class ASummitKnightSeekerMissileTurret : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MissileSpawnPoint;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ASummitKnightSeekerMissile> Missile;


	AHazeActor Target;

	UPROPERTY(EditAnywhere)
	bool bCanFire;

	UPROPERTY(EditAnywhere)
	float StartDelay = 4;

	UPROPERTY(EditAnywhere)
	float FireRate = 4;

	float TurnRate = 1;

	float TimeToFire;

	FVector MissileSpawnLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TimeToFire = Time::GameTimeSeconds + FireRate;
	}

	UFUNCTION()
	private void OnDangerAvoided()
	{
		
		DestroyActor();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bCanFire != true)
			return;

		Target = Game::GetClosestPlayer(ActorLocation);

		FVector ToTarget = Target.ActorCenterLocation - ActorLocation;

		SetActorRotation(ToTarget.ToOrientationQuat());

		if(TimeToFire > Time::GameTimeSeconds)
			return;


		TimeToFire = Time::GameTimeSeconds + FireRate;

		ShootMissile();


	}

	void ShootMissile()
	{
		MissileSpawnLocation = MissileSpawnPoint.WorldLocation;
		SpawnActor(Missile,MissileSpawnLocation, ActorRotation);
	}

	
}