class ASoftSplitStaticTurret : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MissileSpawnPoint;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ASoftSplitTurtlePlatforms> Missile;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;

	UPROPERTY(EditAnywhere)
	bool bCanFire;

	UPROPERTY(EditAnywhere)
	float MissileSpeed;

	UPROPERTY(EditAnywhere)
	float StartDelay;

	UPROPERTY(EditAnywhere)
	float FireRate = 2;

	float TimeToFire;
	bool bStarted = false;

	FVector MissileSpawnLocation;
	int SpawnedCount;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (StartDelay > 0)
			Timer::SetTimer(this, n"Start", StartDelay);
		else
			Start();
	}

	UFUNCTION(BlueprintCallable)
	void Start()
	{
		TimeToFire = Time::GameTimeSeconds + FireRate;
		bStarted = true;
	}

	UFUNCTION(BlueprintCallable)
	void InstantlyLaunch()
	{
		if (HasControl())
			CrumbShootMissile();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bStarted)
			return;
		if(TimeToFire > Time::GameTimeSeconds)
			return;

		TimeToFire = Time::GameTimeSeconds + FireRate;

		if (HasControl())
			CrumbShootMissile();
	}

	UFUNCTION(CrumbFunction)
	void CrumbShootMissile()
	{
		MissileSpawnLocation = MissileSpawnPoint.WorldLocation;
		ASoftSplitTurtlePlatforms MissileSpawned = SpawnActor(Missile, MissileSpawnLocation, ActorRotation, bDeferredSpawn = true);
		MissileSpawned.MakeNetworked(this, SpawnedCount);
		FinishSpawningActor(MissileSpawned);
		MissileSpawned.Speed = MissileSpeed;
		SpawnedCount += 1;
	}

};