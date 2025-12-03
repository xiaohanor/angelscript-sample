class ASoftSplitSplineEnemyTurret : AHazeActor
{

UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MissileSpawnPoint;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ASoftSplitSplineEnemy> Missile;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;

	UPROPERTY(EditAnywhere)
	bool bCanFire;

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
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(TimeToFire > Time::GameTimeSeconds)
				return;

			TimeToFire = Time::GameTimeSeconds + FireRate;
			ShootMissile();
	}

	void ShootMissile()
	{
		if (SplineActor == nullptr)
			return;

		MissileSpawnLocation = MissileSpawnPoint.WorldLocation;
		ASoftSplitSplineEnemy MissileSpawned = Cast<ASoftSplitSplineEnemy> (SpawnActor(Missile, MissileSpawnLocation, ActorRotation, bDeferredSpawn = true));
		MissileSpawned.SplineComp = SplineActor.Spline;
		FinishSpawningActor(MissileSpawned);
		FireRate = Math::RandRange(MinFireRate, MaxFireRate);
	}
};