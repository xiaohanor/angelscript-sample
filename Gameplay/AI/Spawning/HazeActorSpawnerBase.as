event void FOnDepletedSignature(AHazeActor LastActor);
event void FOnPostUnspawnSignature(AHazeActor UnspawnedActor);
event void FOnPostSpawnSignature(AHazeActor SpawnedActor);

UCLASS(Abstract, Meta = (HideCategories = "Tags Collision AssetUserData Cooking Activation Rendering Replication Input Actor LOD Debug"))
class AHazeActorSpawnerBase : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UArrowComponent ArrowComp;
	default ArrowComp.WorldScale3D = FVector(1.5);
	default ArrowComp.ArrowColor = FLinearColor(0.04, 0.4, 0.1);

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
	default Billboard.SpriteName = "Spawner";
	default Billboard.WorldScale3D = FVector(3.0); 
	default Billboard.RelativeLocation = FVector(0.0, 0.0, 150.0);

	UPROPERTY(DefaultComponent)
	UTextRenderComponent MarkerText;
	default MarkerText.IsVisualizationComponent = false;
	default MarkerText.Text = FText::FromString("Spawner");
	default MarkerText.TextRenderColor = FColor::Silver;
	default MarkerText.RelativeLocation = FVector(0.0, 0.0, 350.0);
	default MarkerText.bHiddenInGame = true;
	default MarkerText.WorldSize = 100.0;
	default MarkerText.HorizontalAlignment = EHorizTextAligment::EHTA_Center;
#endif	

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"HazeActorSpawnerCapability");

	UPROPERTY(DefaultComponent, ShowOnActor)
	UHazeActorSpawnerComponent SpawnerComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;

	// Triggers when this actor has completed spawning actors and all spawned actors have been killed.
	UPROPERTY(Category = "Spawner")
	FOnDepletedSignature OnDepleted;

	// Triggers when this actor has completed spawning actors and the last spawned actor has started dying.
	UPROPERTY(Category = "Spawner")
	FOnDepletedSignature OnPreDepleted;

	UPROPERTY(Category = "Spawner")
	FOnPostSpawnSignature OnPostSpawn;

	UPROPERTY(Category = "Spawner")
	FOnPostUnspawnSignature OnPostUnspawn;

	UPROPERTY(Category = "Spawner", AdvancedDisplay, EditInstanceOnly)
	bool bShowLevelSpecificPatterns = false;

	TArray<UHazeActorSpawnPattern> SpawningPatterns;

	bool bIsDepleted = false;
	bool bIsPreDepleted = false;

	UFUNCTION(BlueprintCallable)
	void ActivateSpawner()
	{
		SpawnerComp.ActivateSpawner(this, EInstigatePriority::Low);
	}

	UFUNCTION(BlueprintCallable)
	void DeactivateSpawner()
	{
		SpawnerComp.DeactivateSpawner(this, EInstigatePriority::Low);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SpawnerComp.OnPostUnspawn.AddUFunction(this, n"PostUnspawn");
		SpawnerComp.OnPostSpawn.AddUFunction(this, n"PostSpawn");
		SpawnerComp.OnResetSpawnPatterns.AddUFunction(this, n"OnSpawnPatternReset");

		// Keep track of spawning patterns, for depletion check
		FindSpawningPatterns();

		// Check if any spawn would require capabilities on the players
		TArray<TSubclassOf<AHazeActor>> SpawnClasses;
		HazeActorSpawnPattern::GetSpawnClasses(this, SpawnClasses);
		for (TSubclassOf<AHazeActor> SpawnClass : SpawnClasses)
		{
			if (!SpawnClass.IsValid())
				continue;
			AHazeActor CDO = Cast<AHazeActor>(SpawnClass.Get().GetDefaultObject());
			if (CDO == nullptr)
				continue;
			UHazeRequestCapabilityOnPlayerComponent SpawnRequestComp = UHazeRequestCapabilityOnPlayerComponent::Get(CDO);
			if (SpawnRequestComp == nullptr)
				continue;
			// This will now merge requests correctly
			RequestComp.AppendRequestsFromOtherComponent(SpawnRequestComp);
		}
	}

	void FindSpawningPatterns()
	{
		TArray<UHazeActorSpawnPattern> SpawnPatterns;
		GetComponentsByClass(SpawnPatterns);
		for (UHazeActorSpawnPattern Pattern : SpawnPatterns)
		{
			if (Pattern.CanSpawn())
				SpawningPatterns.AddUnique(Pattern);
		}
	}

	UFUNCTION()
	private void PostSpawn(AHazeActor SpawnedActor, UHazeActorSpawnerComponent Spawner,
	                         UHazeActorSpawnPattern SpawningPattern)
	{
		if (Spawner != SpawnerComp)
			return;

		OnPostSpawn.Broadcast(SpawnedActor);

		if (OnPreDepleted.IsBound())
		{
			UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(SpawnedActor);
			if (HealthComp != nullptr)
				HealthComp.OnStartDying.AddUFunction(this, n"OnSpawnedActorStartDying");
		}
	}

	UFUNCTION()
	private void OnSpawnedActorStartDying(AHazeActor ActorBeingKilled)
	{
		UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(ActorBeingKilled);
		if (HealthComp != nullptr)
			HealthComp.OnStartDying.Unbind(this, n"OnSpawnedActorStartDying");

		// No active spawn currently, can we spawn more?
		if (CheckRemainingActorsToSpawn())
			return;

		// We're predepleted if this is the last dying actor we'll ever spawn
		UHazeTeam SpawnTeam = SpawnerComp.GetSpawnedActorsTeam();
		
		// Clear out any invalid members which we can get under specific circumstances in cooked TODO: Investigate!
		if (SpawnTeam != nullptr)
			SpawnTeam.RemoveMember(nullptr);

		// Do we have any member that is still alive?
		TArray<AHazeActor> Members = SpawnTeam.GetMembers();
		for (AHazeActor Member : Members)
		{
			UBasicAIHealthComponent MemberHealthComp = UBasicAIHealthComponent::Get(Member);
			if (MemberHealthComp == nullptr)
				return; // Early out, these members can't trigger OnStartDying.
			
			if (!MemberHealthComp.IsDying())
				return; // Found non-dying member.
		}

		// Final spawned actor has started dying
		if (HasControl())
			CrumbTriggerPreDepleted(ActorBeingKilled);
	}

	UFUNCTION()
	private void PostUnspawn(AHazeActor UnspawnedActor, UHazeActorSpawnerComponent Spawner, UHazeActorSpawnPattern SpawningPattern)
	{
		if (Spawner != SpawnerComp)
			return;

		OnPostUnspawn.Broadcast(UnspawnedActor);

		if (OnPreDepleted.IsBound())
		{
			UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(UnspawnedActor);
			if (HealthComp != nullptr)
				HealthComp.OnStartDying.Unbind(this, n"OnSpawnedActorStartDying");
		}

		// We're depleted if this was the last actor we'll ever spawn
		UHazeTeam SpawnTeam = SpawnerComp.GetSpawnedActorsTeam();
		
		// Clear out any invalid members which we can get under specific circumstances in cooked TODO: Investigate!
		if (SpawnTeam != nullptr)
			SpawnTeam.RemoveMember(nullptr); 
		
		if ((SpawnTeam != nullptr) && (SpawnTeam.GetMembers().Num() > 0))
			return; // There are still active spawned actors

		// No active spawn currently, can we spawn more?
		if (!CheckRemainingActorsToSpawn() && HasControl())
		{
			// Final spawned actor was unspawned
			bIsDepleted = true;
			if (!bIsPreDepleted) 
			{
				// if we for any reason did not trigger OnPreDepleted, trigger it now.
				CrumbTriggerPreDepleted(UnspawnedActor);
			}
			CrumbTriggerDepleted(UnspawnedActor);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbTriggerPreDepleted(AHazeActor LastActorToDie)
	{
		bIsPreDepleted = true;
		OnPreDepleted.Broadcast(LastActorToDie);
	}

	UFUNCTION(CrumbFunction)
	void CrumbTriggerDepleted(AHazeActor LastUnspawnedActor)
	{
		bIsDepleted = true;
		OnDepleted.Broadcast(LastUnspawnedActor);
	}

	// Is true if all actors that can be spawned has done so and been killed.
	UFUNCTION(BlueprintPure)
	bool IsDepleted()
	{
		return bIsDepleted;
	}

	// Is true if all actors that can be spawned has done so and started dying.
	UFUNCTION(BlueprintPure)
	bool IsPreDepleted()
	{
		return bIsPreDepleted;
	}

	private bool CheckRemainingActorsToSpawn()
	{
		// Clear out any completed spawningpatterns
		for (int i = SpawningPatterns.Num() - 1; i >= 0; i--)
		{
			if (SpawningPatterns[i].IsCompleted())
				SpawningPatterns.RemoveAtSwap(i);
		}
		// If any spawning pattern remains, we have remaining actors to spawn
		if (SpawningPatterns.Num() == 0)
			return false;
		return true;
	}

	UFUNCTION()
	private void OnSpawnPatternReset(UHazeActorSpawnerComponent Spawner)
	{
		bIsPreDepleted = false;
		bIsDepleted = false;
		FindSpawningPatterns();
	}
}
