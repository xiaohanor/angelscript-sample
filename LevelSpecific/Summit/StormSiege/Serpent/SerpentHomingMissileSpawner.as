class ASerpentHomingMissileSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	TSubclassOf<ASerpentHomingMissile> MissileClass;

	AHazePlayerCharacter TargetPlayer;

	int MaxSpawns = 10;
	int CurrentSpawns;
	float SpawnRate = 0.3;
	float SpawnTime;

	float MissileTargetSpeed = 4500.0;

	float TEMPDebugSphereRadius = 700.0;

	bool bShowDebug = true;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds > SpawnTime)
		{
			SpawnMissile();
			CurrentSpawns++;
			SpawnTime = Time::GameTimeSeconds + SpawnRate;
		}

		if (bShowDebug)
			Debug::DrawDebugSphere(ActorLocation, TEMPDebugSphereRadius, 25.0, FLinearColor::Red, 120.0);

		if (CurrentSpawns > MaxSpawns)
			DestroyActor();
	}

	void SpawnMissile()
	{
		ASerpentHomingMissile Missile = SpawnActor(MissileClass, ActorLocation, bDeferredSpawn = true);
		Missile.TargetPlayer = TargetPlayer; 
		Missile.TargetSpeed = MissileTargetSpeed;
		FinishSpawningActor(Missile);
	}
}