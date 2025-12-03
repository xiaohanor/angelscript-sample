event void FOnStormKnightDefeated();

UCLASS(Abstract)
class AStormKnight : AHazeActor
{
	UPROPERTY()
	FOnStormKnightDefeated OnStormKnightDefeated; 

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MagicWaveSpawnLoc;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UHazeSkeletalMeshComponentBase SkeletalMesh;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"StormKnightLightningCapability");

	UPROPERTY()
	UStormKnightSettings StormKnightSettings;
	
	UPROPERTY()
	TSubclassOf<AStormKnightLightningAttack> LightningAttackClass;

	UPROPERTY(EditAnywhere)
	TArray<AStormKnightGem> Gems;

	TArray<AActor> AttachedActors;
	TArray<FInstigator> Disablers;
	int MaxGemDestroyedCount;
	int GemDestroyedCount;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ApplyDefaultSettings(StormKnightSettings);

		GetAttachedActors(AttachedActors);
		for (AActor Actor : AttachedActors)
		{
			AStormKnightGem NewGem = Cast<AStormKnightGem>(Actor);
			if (NewGem != nullptr)
				Gems.Add(NewGem);
		}

		for (AStormKnightGem Gem : Gems)
		{
			Gem.OnSummitGemDestroyed.AddUFunction(this, n"OnSummitGemDestroyed");
		}

		MaxGemDestroyedCount = Gems.Num();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Debug::DrawDebugSphere(GetClosestPlayer().ActorLocation, 200.0, LineColor = FLinearColor::Red);
	}

	void SpawnLightningAttack()
	{
		FVector SpawnLocation = ActorLocation + (ActorForwardVector * 1500.0) + FVector(0.0, 0.0, 4000.0);
		AStormKnightLightningAttack LightningAttack = SpawnActor(LightningAttackClass, SpawnLocation, bDeferredSpawn = true);
		FStormKnightLightningParams Params;
		Params.Start = SpawnLocation;
		FVector Direction = (GetClosestPlayer().ActorLocation - SpawnLocation).GetSafeNormal();
		Params.End = GetClosestPlayer().ActorLocation;
		Params.Width = 2.0; 
		LightningAttack.Params = Params;
		FinishSpawningActor(LightningAttack);
	}

	UFUNCTION()
	private void OnSummitGemDestroyed(ASummitNightQueenGem CrystalDestroyed)
	{
		GemDestroyedCount++;

		if (GemDestroyedCount == MaxGemDestroyedCount)
			DestroySummitStormKnight();
	}

	UFUNCTION()
	void DestroySummitStormKnight()
	{
		for (AActor Actor : AttachedActors)
		{
			Actor.DestroyActor();
		}

		for (AStormKnightGem Gem : Gems)
		{
			if (Gem != nullptr)
				Gem.DestroyActor();
		}

		DestroyActor();
	}

	UFUNCTION()
	void AddDisabler(FInstigator Disabler)
	{
		Disablers.AddUnique(Disabler);
	}

	UFUNCTION()
	void RemoveDisabler(FInstigator Disabler)
	{
		if (!Disablers.Contains(Disabler))
			Disablers.Remove(Disabler);
	}

	AHazePlayerCharacter GetClosestPlayer()
	{
		return GetDistanceTo(Game::Mio) < GetDistanceTo(Game::Zoe) ? Game::Mio : Game::Zoe;
	}
}