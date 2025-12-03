class AMeltdownScreenWalkTurret : AHazeActor
{
UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MissileSpawnPoint;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AMeltdownScreenWalkEnemy> Missile;

	UPROPERTY(EditAnywhere)
	AMeltdownScreenWalkEnemySplineLauncher EnemyLauncher;

	UPROPERTY(EditAnywhere)
	bool bCanFire;

	UPROPERTY(EditAnywhere)
	bool bIsOneShot;

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

		EnemyLauncher.EnemyLanded.AddUFunction(this, n"SpawnEnemy");

		if(bIsOneShot)
		{
			SetActorTickEnabled(false);
		}
	}

	UFUNCTION()
	private void SpawnEnemy()
	{
		ShootMissile();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

		if(TimeToFire > Time::GameTimeSeconds)
				return;

			TimeToFire = Time::GameTimeSeconds + FireRate;
		if(bCanFire)
			ShootMissile();
	}

	UFUNCTION(BlueprintCallable)
	void ShootMissile()
	{
		MissileSpawnLocation = MissileSpawnPoint.WorldLocation;
		AMeltdownScreenWalkEnemy MissileSpawned = Cast<AMeltdownScreenWalkEnemy> (SpawnActor(Missile, MissileSpawnLocation, ActorRotation, bDeferredSpawn = true));
		FinishSpawningActor(MissileSpawned);
		FireRate = Math::RandRange(MinFireRate, MaxFireRate);
		MissileSpawned.Speed = MissileSpeed;
		MissileEvent();
	}

	UFUNCTION(BlueprintEvent)
	void MissileEvent()
	{
		
	}
};