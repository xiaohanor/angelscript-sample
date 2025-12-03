class ASkylineFlyingCarEnemyMissileTurret : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent GunRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;
	
	UPROPERTY(DefaultComponent, Attach = GunRoot)
	UArrowComponent SpawnPoint;

	// UPROPERTY(DefaultComponent, Attach = Root)
	// UBoxComponent TriggerBox;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ASkylineFlyingCarEnemyMissile> Missile;

	UPROPERTY(EditAnywhere)
	float ShootMissileDelay = 0;
	float TimeToShootMissile;


	UPROPERTY(EditAnywhere)
	AActorTrigger Trigger;

	ASkylineFlyingCar FlyingCar;

	bool bIsReadyToShootMissile;
	bool bMissileShot;



	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Trigger.OnActorEnter.AddUFunction(this, n"OnActorEnter");
		
	}


	UFUNCTION()
	private void OnActorEnter(AHazeActor Actor)
	{
		FlyingCar = Cast<ASkylineFlyingCar>(Actor);

		if(FlyingCar == nullptr)
			return;

		SetActorControlSide(FlyingCar.Gunner);

		TimeToShootMissile = Time::GameTimeSeconds + ShootMissileDelay;
		bIsReadyToShootMissile = true;
	}

	


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bMissileShot)
			return;

		if(!bIsReadyToShootMissile)
			return;
			
		if(!HasControl())
			return;

		if(TimeToShootMissile <= Time::GameTimeSeconds)
		{
			CrumbSpawnMissile();
		}

	}

	UFUNCTION(CrumbFunction)
	void CrumbSpawnMissile()
	{
		AActor SpawnedActor = SpawnActor(Missile, SpawnPoint.WorldLocation, SpawnPoint.WorldRotation);
		ASkylineFlyingCarEnemyMissile SpawnedMissile = Cast<ASkylineFlyingCarEnemyMissile>(SpawnedActor);
		SpawnedMissile.FlyingCar = FlyingCar;
		SpawnedMissile.MakeNetworked(this);
		SpawnedMissile.SetActorControlSide(this);

		bMissileShot = true;
	}

};