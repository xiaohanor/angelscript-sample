class AMeltdownBossPhaseThreeFakeFallingObstacleSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent)	
	UBillboardComponent SpawnerMesh;

	FVector SpawnCenter;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AMeltdownBossPhaseThreeFakeFallingObjects> Obstacle;

	UPROPERTY(EditAnywhere)
	float SpawnInterval;

	int SpawnCounter = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SpawnCenter = SpawnerMesh.WorldLocation;

	}

	UFUNCTION(BlueprintCallable)
	void Launch()
	{
		SpawnObstacle();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SpawnCenter = SpawnerMesh.WorldLocation;
		
	}

	UFUNCTION()
	void SpawnObstacle()
	{
		AMeltdownBossPhaseThreeFakeFallingObjects SpawnedObstacle = Cast<AMeltdownBossPhaseThreeFakeFallingObjects> (SpawnActor(Obstacle,SpawnCenter, ActorRotation, bDeferredSpawn = true));
		SpawnedObstacle.MakeNetworked(this, SpawnCounter);
		SpawnCounter += 1;
		FinishSpawningActor(SpawnedObstacle);
		Timer::SetTimer(this,n"SpawnObstacle", SpawnInterval, bLooping = true);
	}
};