class AMeltdownGemSpearTurret : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SpearSpawnPoint;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AGemMissile> Spear;

	AHazePlayerCharacter Target;

	UPROPERTY()
	bool bCanFire;

	UPROPERTY(EditAnywhere)
	float StartDelay = 4;

	UPROPERTY(EditAnywhere)
	float FireRate = 4;

	float TurnRate = 1;

	float TimeToFire;

	FVector SpearSpawnLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TimeToFire = Time::GameTimeSeconds + FireRate;
		SpearSpawnLocation = SpearSpawnPoint.WorldLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bCanFire != true)
			return;

		 Target = Game::GetClosestPlayer(ActorLocation);

		// FVector ToTarget = Target.ActorCenterLocation - ActorLocation;

		// SetActorRotation(ToTarget.ToOrientationQuat());

		if(TimeToFire > Time::GameTimeSeconds)
			return;


		TimeToFire = Time::GameTimeSeconds + FireRate;
		
		ShootSpear();


	}

	void ShootSpear()
	{
		AGemMissile NewSpear = SpawnActor(Spear,SpearSpawnLocation, ActorRotation, bDeferredSpawn = true);
		NewSpear.StartLocation = ActorLocation + FVector(0.0, 0.0, 300.0);
		NewSpear.TargetPlayer = Target;
		FinishSpawningActor(NewSpear);
	}

	
}