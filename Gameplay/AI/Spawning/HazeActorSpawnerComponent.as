event void FOnHazeActorSpawnerPostSpawn(AHazeActor SpawnedActor, UHazeActorSpawnerComponent Spawner, UHazeActorSpawnPattern SpawningPattern);
event void FOnHazeActorSpawnerPostUnspawn(AHazeActor UnspawnedActor, UHazeActorSpawnerComponent Spawner, UHazeActorSpawnPattern SpawningPattern);
event void FOnHazeActorSpawnerReset(UHazeActorSpawnerComponent Spawner);

UCLASS(Meta = (HideCategories = "Activation Cooking Tags Collision"))
class UHazeActorSpawnerComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	// If true, this spawner will start checking spawn pattern when beginning play.
	UPROPERTY(EditAnywhere, Category = "Spawner")
	bool bStartActivated = false;

	UPROPERTY(BlueprintReadOnly, Category = "Spawner")
	FOnHazeActorSpawnerPostSpawn OnPostSpawn;

	UPROPERTY(BlueprintReadOnly, Category = "Spawner")
	FOnHazeActorSpawnerPostUnspawn OnPostUnspawn;

	UPROPERTY(BlueprintReadOnly, Category = "Spawner")
	FOnHazeActorSpawnerReset OnResetSpawnPatterns;

	FName TeamName;
	AHazeActor HazeOwner;

	private TInstigated<bool> bIsActive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bStartActivated)
			bIsActive.SetDefaultValue(true);

		TeamName = FName("" + GetPathName());
		HazeOwner = Cast<AHazeActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		// All members will leave spawner team so it won't remain in cooked with nullptr members.
		UHazeTeam Team = GetSpawnedActorsTeam();
		if (Team != nullptr)
		{
			TArray<AHazeActor> Members = Team.GetMembers();
			for (AHazeActor Spawn : Members)
			{
				if (Spawn == nullptr)
					continue;
				Spawn.LeaveTeam(TeamName);
			}
		}
	}

	UFUNCTION()
	UHazeTeam GetSpawnedActorsTeam() property
	{
		return HazeTeam::GetTeam(TeamName);
	}

	UFUNCTION()
	void ActivateSpawner(FInstigator Instigator, EInstigatePriority Prio = EInstigatePriority::Low)
	{
		bIsActive.Apply(true, Instigator, Prio);
	}

	UFUNCTION()
	void DeactivateSpawner(FInstigator Instigator, EInstigatePriority Prio = EInstigatePriority::Low)
	{
		bIsActive.Apply(false, Instigator, Prio);
	}

	UFUNCTION()
	void ClearActivation(FInstigator Instigator)
	{
		bIsActive.Clear(Instigator);
	}

	UFUNCTION(BlueprintPure)
	bool IsSpawnerActive() const
	{
		return bIsActive.Get();
	}

	// Reset all spawn patterns to their original state. Use with care! This does not affect activation status, so make sure you deactivate or activate the spawner as well.
	UFUNCTION(BlueprintCallable)
	void ResetSpawnPatterns()
	{
		TArray<UHazeActorSpawnPattern> Patterns;
		Owner.GetComponentsByClass(Patterns);
		for (UHazeActorSpawnPattern Pattern : Patterns)
		{
			Pattern.ResetPattern();
		}
		OnResetSpawnPatterns.Broadcast(this);
	}

	UFUNCTION()
	void ActivatePatternByTag(FName Tag, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Low)
	{
		TArray<UHazeActorSpawnPattern> Patterns;
		Owner.GetComponentsByClass(Patterns);
		for (UHazeActorSpawnPattern Pattern : Patterns)
		{
			if (Pattern.HasTag(Tag))
				Pattern.ActivatePattern(Instigator, Priority);
		}
	}

	UFUNCTION()
	void DeactivatePatternByTag(FName Tag, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Low)
	{
		TArray<UHazeActorSpawnPattern> Patterns;
		Owner.GetComponentsByClass(Patterns);
		for (UHazeActorSpawnPattern Pattern : Patterns)
		{
			if (Pattern.HasTag(Tag))
				Pattern.DeactivatePattern(Instigator, Priority);
		}
	}

	UFUNCTION()
	void ClearPatternActivationByTag(FName Tag, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Low)
	{
		TArray<UHazeActorSpawnPattern> Patterns;
		Owner.GetComponentsByClass(Patterns);
		for (UHazeActorSpawnPattern Pattern : Patterns)
		{
			if (Pattern.HasTag(Tag))
				Pattern.ClearPatternActivation(Instigator);
		}
	}

	void SortSpawnPatterns(TArray<UHazeActorSpawnPattern>& Patterns)
	{
		// Insert sort, should not be that any items...
		TArray<UHazeActorSpawnPattern> Sorted;
		Sorted.Reserve(Patterns.Num());
		for (int i = 0; i < Patterns.Num(); i++)
		{
			int j = 0;
			for (; (j < i) && (Patterns[i].UpdateOrder >= Sorted[j].UpdateOrder); j++){};
			Sorted.Insert(Patterns[i], j);
		}
		Patterns = Sorted;
	}

	// Kill any currently spawned actors
	UFUNCTION(BlueprintCallable)
	void KillSpawnedAI(AHazeActor Instigator = nullptr)
	{
		AHazeActor InstigatorActor = Instigator;
		if (InstigatorActor == nullptr)
			InstigatorActor = (HazeOwner != nullptr) ? HazeOwner : Game::Mio; // It's all Mios fault
		UHazeTeam Team = GetSpawnedActorsTeam();
		if (Team == nullptr)
			return;

		TArray<AHazeActor> TeamMembers = Team.GetMembers();
		for (AHazeActor Spawn : TeamMembers)
		{
			if (Spawn == nullptr)
				continue; // TODO: In network, team members sometimes do not get removed when destroyed. Will investigate and fix this, but in worst case we might need nullptr checking. 
			UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(Spawn);	
			if (HealthComp == nullptr)
				continue;
			HealthComp.TakeDamage(HealthComp.MaxHealth, EDamageType::Default, InstigatorActor);
		}
	}

	UFUNCTION(BlueprintCallable)
	void MakeSpawnedAIsFlee()
	{
		UHazeTeam Team = GetSpawnedActorsTeam();
		if (Team == nullptr)
			return;

		TArray<AHazeActor> TeamMembers = Team.GetMembers();
		for (AHazeActor Spawn : TeamMembers)
		{
			if (Spawn == nullptr)
				continue; 
			UBasicAIFleeingComponent FleeComp = UBasicAIFleeingComponent::Get(Spawn);	
			if (FleeComp == nullptr)
				continue;
			FleeComp.Flee();
		}
	}

	UFUNCTION(BlueprintCallable, meta = (DefaultToSelf = "Instigator"))
	void DisableSpawnedActors(FInstigator Instigator)
	{
		UHazeTeam Team = GetSpawnedActorsTeam();
		if (Team == nullptr)
			return;
		for (AHazeActor Spawn : Team.GetMembers())
		{
			if (Spawn == nullptr)
				continue;
			Spawn.AddActorDisable(Instigator);
		}
	}
}

