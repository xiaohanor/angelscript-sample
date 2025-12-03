class AMeltdownBossPhaseTwoFireWormSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MissileSpawnPoint;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AMeltdownBossPhaseTwoFireWorm> Missile;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;

	float FireRate = 0.5;

	float TimeToFire;

	int MaxSpawn;

	FVector MissileSpawnLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TimeToFire = Time::GameTimeSeconds + FireRate;
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintCallable)
	void StartWorm()
	{
		SetActorTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

		if(TimeToFire > Time::GameTimeSeconds)
				return;

			TimeToFire = Time::GameTimeSeconds + FireRate;
			MaxSpawn += 1;
			if(MaxSpawn >= 3)
			AddActorDisable(this);
			ShootMissile();
			
	}

	UFUNCTION(BlueprintCallable)
	void ShootMissile()
	{
		MissileSpawnLocation = MissileSpawnPoint.WorldLocation;
		AMeltdownBossPhaseTwoFireWorm MissileSpawned = Cast<AMeltdownBossPhaseTwoFireWorm> (SpawnActor(Missile, MissileSpawnLocation, ActorRotation, bDeferredSpawn = true));
		MissileSpawned.SplineComp = SplineActor.Spline;
		FinishSpawningActor(MissileSpawned);
	}
};