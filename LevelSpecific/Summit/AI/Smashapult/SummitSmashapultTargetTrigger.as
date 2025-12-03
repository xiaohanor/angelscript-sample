class ASummitSmashapultTargetTrigger : APlayerTrigger
{
	// Zoe only
	default bTriggerForZoe = true;
	default bTriggerForMio = false;

	// No need for networking, smashapult targeting is always handled on Zoe side only
	default bTriggerLocally = true;

	// Any smashapults spawned by these spawners will use this targeting volume
	UPROPERTY(EditAnywhere, Category = "Targeting")
	TArray<AHazeActorSpawnerBase> SmashapultSpawners;
	default SmashapultSpawners.SetNumZeroed(1);

	// These smashapults will use this targeting volume
	UPROPERTY(EditAnywhere, Category = "Targeting")
	TArray<AAISummitSmashapult> Smashapults;

	bool bTargetInside = false;
	TArray<AAISummitSmashapult> BlockedActors;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UDummyVisualizationComponent DummyVisComp;
	default DummyVisComp.Color = FLinearColor::Green;	
	default DummyVisComp.Thickness = 10.0;

	UPROPERTY(DefaultComponent)
	UDummyVisualizationComponent DummyVisCompBadSpawners;
	default DummyVisCompBadSpawners.Color = FLinearColor::Red;	
	default DummyVisComp.Thickness = 6.0;
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		// Block attacks for all smashapults until player enter trigger
		MakeLoveNotWar();

		// Add smashapults as they spawn
		for (AHazeActorSpawnerBase Spawner : SmashapultSpawners)
		{
			Spawner.OnPostSpawn.AddUFunction(this, n"OnSpawnedSmashapult");	
		}

		OnPlayerEnter.AddUFunction(this, n"OnEntering");
		OnPlayerLeave.AddUFunction(this, n"OnLeaving");
	}

	UFUNCTION()
	private void OnSpawnedSmashapult(AHazeActor SpawnedActor)
	{
		AAISummitSmashapult Smashapult = Cast<AAISummitSmashapult>(SpawnedActor);
		if (Smashapult == nullptr)
			return;
		
		Smashapults.AddUnique(Smashapult);
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Smashapult);
		RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawnedSmashapult");

		if (!bTargetInside)
		{
			USummitSmashapultComponent::GetOrCreate(Smashapult).PeaceKeepers.AddUnique(this);
			BlockedActors.AddUnique(Smashapult);
		}
	}

	UFUNCTION()
	private void OnUnspawnedSmashapult(AHazeActor Actor)
	{
		AAISummitSmashapult Smashapult = Cast<AAISummitSmashapult>(Actor);
		if (Smashapult == nullptr)
			return;

		Smashapults.RemoveSingleSwap(Smashapult);
		if (BlockedActors.Contains(Smashapult))
		{
			USummitSmashapultComponent::GetOrCreate(Smashapult).PeaceKeepers.RemoveSingleSwap(this);
			BlockedActors.RemoveSingleSwap(Smashapult);
		}

		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Smashapult);
		RespawnComp.OnUnspawn.UnbindObject(this);
	}

	UFUNCTION()
	private void OnEntering(AHazePlayerCharacter Player)
	{
		if (!Player.IsZoe())
			return;

		bTargetInside = true;		

		for (AAISummitSmashapult Pult : BlockedActors)
		{
			USummitSmashapultComponent::GetOrCreate(Pult).PeaceKeepers.RemoveSingleSwap(this);
		}	
	}

	UFUNCTION()
	private void OnLeaving(AHazePlayerCharacter Player)
	{
		if (!Player.IsZoe())
			return;

		bTargetInside = false;
		MakeLoveNotWar();
	}

	void MakeLoveNotWar()
	{
		for (AAISummitSmashapult Pult : Smashapults)
		{
			USummitSmashapultComponent::GetOrCreate(Pult).PeaceKeepers.AddUnique(this);
		}
		BlockedActors = Smashapults;
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		bTriggerForMio = false;

#if EDITOR
		// Visualize connections.
		DummyVisComp.ConnectedActors.Empty(SmashapultSpawners.Num() + Smashapults.Num());
		DummyVisCompBadSpawners.ConnectedActors.Empty();
		for (auto Spawner : SmashapultSpawners)
		{
			if (IsSmashapultSpawner(Spawner))
				DummyVisComp.ConnectedActors.Add(Spawner);
			else
				DummyVisCompBadSpawners.ConnectedActors.Add(Spawner);
		}
		for (auto Smashapult : Smashapults)
		{
			DummyVisComp.ConnectedActors.Add(Smashapult);
		}
#endif
	}

	bool IsSmashapultSpawner(AActor Actor)
	{
		if (Actor == nullptr)
			return false;

		TArray<UHazeActorSpawnPattern> SpawnPatterns;
		Actor.GetComponentsByClass(SpawnPatterns);
		for (UHazeActorSpawnPattern Pattern : SpawnPatterns)
		{
			TArray<TSubclassOf<AHazeActor>> SpawnClasses;
			Pattern.GetSpawnClasses(SpawnClasses);
			for (TSubclassOf<AHazeActor> SpawnClass : SpawnClasses)
			{
				if (SpawnClass.Get().IsChildOf(AAISummitSmashapult))	
					return true;
			}
		}
		return false;
	}
}
