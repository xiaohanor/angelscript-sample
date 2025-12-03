class AMeltdownBossPhaseThreeFallingObstacleSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent)	
	UBillboardComponent SpawnerMesh;

	FVector SpawnCenter;
	FVector Size = FVector(200,200,10);

	UPROPERTY(EditDefaultsOnly, Meta = (ArraySizeEnum = "/Script/Angelscript.EMeltdownPhaseThreeFallingWorld"))
	TArray<TSubclassOf<AMeltdownBossPhaseThreeFallingObstacle>> ObstacleTypes;
	default ObstacleTypes.SetNum(EMeltdownPhaseThreeFallingWorld::MAX);

	UPROPERTY(EditAnywhere)
	AMeltdownBossFlyingPhaseManager Manager;

	UPROPERTY(EditAnywhere)
	AMeltdownBossPhaseThreeDummyRaderFalling Rader;

	UPROPERTY(EditAnywhere)
	AMeltdownGlitchShootingPickup Pickup;

	UPROPERTY(EditAnywhere)
	float SpawnInterval;
	UPROPERTY(EditAnywhere)
	float LeadPredictTime = 0.5;

	AHazePlayerCharacter NextTargetPlayer;
	int SpawnCounter = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SpawnCenter = SpawnerMesh.WorldLocation;
		NextTargetPlayer = Game::Mio;
	}

	UFUNCTION(BlueprintCallable)
	void Launch()
	{
		if (HasControl())
			SpawnObstacle();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SpawnCenter = SpawnerMesh.WorldLocation;

		if(Manager.FallingDone)
		{
			AddActorDisable(this);
			Timer::ClearTimer(this, n"SpawnObstacle");
		}
		
	}

	UFUNCTION(BlueprintCallable)
	void StopSpawning()
	{
		AddActorDisable(this);
		Timer::ClearTimer(this, n"SpawnObstacle");
	}

	UFUNCTION()
	void SpawnObstacle()
	{
		Timer::SetTimer(this,n"SpawnObstacle", SpawnInterval, bLooping = false);

		FVector SpawnLocation = NextTargetPlayer.ActorLocation + NextTargetPlayer.ActorVelocity * LeadPredictTime;
		SpawnLocation.Z = SpawnCenter.Z;

		auto SkydiveComp = UMeltdownSkydiveComponent::Get(Game::Mio);
		if (!ObstacleTypes.IsValidIndex(SkydiveComp.CurrentWorld))
			return;

		auto Obstacle = ObstacleTypes[SkydiveComp.CurrentWorld];
		if (!Obstacle.IsValid())
			return;

		NetSpawnObstacle(SpawnLocation, Obstacle);
		NextTargetPlayer = NextTargetPlayer.OtherPlayer;
	}

	UFUNCTION(NetFunction)
	void NetSpawnObstacle(FVector SpawnLocation, TSubclassOf<AMeltdownBossPhaseThreeFallingObstacle> Obstacle)
	{
		AMeltdownBossPhaseThreeFallingObstacle SpawnedObstacle = SpawnActor(Obstacle, SpawnLocation, ActorRotation, bDeferredSpawn = true);
		SpawnedObstacle.MakeNetworked(this, SpawnCounter);
		SpawnCounter++;
		FinishSpawningActor(SpawnedObstacle);
	}
};