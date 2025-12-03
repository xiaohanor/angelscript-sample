class AGemSpawnPointActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	ASummitNightQueenGem GemInUse;

	void SetGemInUse(ASummitNightQueenGem Gem)
	{
		GemInUse = Gem;
		GemInUse.OnSummitGemDestroyed.AddUFunction(this, n"OnSummitGemDestroyed");
	}

	UFUNCTION()
	private void OnSummitGemDestroyed(ASummitNightQueenGem CrystalDestroyed)
	{
		// RemoveGemInUse();
	}

	void RemoveGemInUse()
	{
		GemInUse = nullptr;
	}
}

event void FOnTreasureTempleTrapSpawnComplete();

UCLASS(Abstract)
class ATreasureTempleGemTrapSpawner : AHazeActor
{
	UPROPERTY()
	FOnTreasureTempleTrapSpawnComplete OnTreasureTempleTrapSpawnComplete;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(10.0));
#endif

	UPROPERTY()
	TSubclassOf<ATreasureTempleGemTrap> GemTrapClass;

	//TArray<AGemSpawnPointActor> SpawnPoints;
	// TArray<AGemSpawnPointActor> AvailableSpawnPoints;

	float SpawnRate = 0.5;
	float SpawnTime;
	int MaxIndex;
	int CurrentIndex;
	int NumberTrapsSpawned = 0;

	bool bGetMio;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TListedActors<AGemSpawnPointActor> SpawnPoints;
		MaxIndex = SpawnPoints.Num() - 1;
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds > SpawnTime)
		{
			SpawnTime = Time::GameTimeSeconds + SpawnRate;
			SpawnTrap();
			CurrentIndex++;

			if (CurrentIndex >= MaxIndex)
			{
				DeactivateSpawns();
				OnTreasureTempleTrapSpawnComplete.Broadcast();
			}
		}
		// AvailableSpawnPoints = SpawnPoints;
	}

	void FindSpawnPoint()
	{
		if (!SpawnPointAvailable())
			return;

		// int RPoint = Math::RandRange(0, SpawnPoints.Num() - 1);

		// ATreasureTempleGemTrap Trap = SpawnActor(GemTrapClass, ActorLocation, bDeferredSpawn = true);
		// FinishSpawningActor(Trap);
		// AvailableSpawnPoints[RPoint].GemInUse = Trap;
	}

	UFUNCTION()
	void ManualOneTimeSpawn()
	{
		TListedActors<AGemSpawnPointActor> SpawnPoints;
		for (AGemSpawnPointActor Point : SpawnPoints)
		{
			ATreasureTempleGemTrap Trap = SpawnActor(GemTrapClass, ActorLocation, bDeferredSpawn = true);
			Trap.TargetDirection = (Point.ActorLocation - ActorLocation).GetSafeNormal();
			Trap.MakeNetworked(this, NumberTrapsSpawned);
			NumberTrapsSpawned++;
			FinishSpawningActor(Trap);			
			Trap.SetTelegraphMode(Point.ActorLocation);
		}
	}

	void SpawnTrap()
	{
		TListedActors<AGemSpawnPointActor> SpawnPoints;
		ATreasureTempleGemTrap Trap = SpawnActor(GemTrapClass, ActorLocation, bDeferredSpawn = true);
		Trap.TargetDirection = (SpawnPoints[CurrentIndex].ActorLocation - ActorLocation).GetSafeNormal();
		Trap.MakeNetworked(this, NumberTrapsSpawned);
		NumberTrapsSpawned++;
		FinishSpawningActor(Trap);	
		Trap.SetTelegraphMode(SpawnPoints[CurrentIndex].ActorLocation);
	}

	// AHazePlayerCharacter GetTarget()
	// {
	// 	bGetMio = !bGetMio;

	// 	if (bGetMio)
	// 		return Game::Mio;
	// 	else
	// 		return Game::Zoe;
	// }

	UFUNCTION()
	void ActivateSpawns()
	{
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void DeactivateSpawns()
	{
		SetActorTickEnabled(false);
	}

	bool SpawnPointAvailable()
	{
		// for (AGemSpawnPointActor Point : SpawnPoints)
		// {
		// 	if (Point.GemInUse == nullptr)
		// 		return true;
		// }

		return false;
	}
}