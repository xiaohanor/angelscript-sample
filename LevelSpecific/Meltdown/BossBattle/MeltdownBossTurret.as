class AMeltdownBossTurret : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MissileSpawnPoint;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AMeltdownBossPhaseOneSplineWorm> Missile;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;

	UPROPERTY(EditAnywhere)
	bool bCanFire;

	UPROPERTY(EditAnywhere)
	bool bOneShot;

	UPROPERTY(EditAnywhere)
	float MissileSpeed;

	UPROPERTY(EditAnywhere)
	float MaxFireRate = 4;

	UPROPERTY(EditAnywhere)
	float MinFireRate = 2;

	float FireRate = 2;

	float TimeToFire;

	FVector MissileSpawnLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FireRate = Math::RandRange(MinFireRate, MaxFireRate);
		TimeToFire = Time::GameTimeSeconds + FireRate;

		if(bOneShot)
		{
			bCanFire = true;
			SetActorTickEnabled(false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

		if(TimeToFire > Time::GameTimeSeconds)
				return;

			TimeToFire = Time::GameTimeSeconds + FireRate;
			ShootMissile();
	}

	UFUNCTION(BlueprintCallable)
	void ShootMissile()
	{
		MissileSpawnLocation = MissileSpawnPoint.WorldLocation;
		AMeltdownBossPhaseOneSplineWorm MissileSpawned = Cast<AMeltdownBossPhaseOneSplineWorm> (SpawnActor(Missile, MissileSpawnLocation, ActorRotation, bDeferredSpawn = true));
		MissileSpawned.SplineComp = SplineActor.Spline;
		FinishSpawningActor(MissileSpawned);
		FireRate = Math::RandRange(MinFireRate, MaxFireRate);
		MissileSpawned.Speed = MissileSpeed;
	}

};