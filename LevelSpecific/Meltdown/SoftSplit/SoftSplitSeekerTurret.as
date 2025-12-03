class ASoftSplitSeekerTurret : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	UStaticMeshComponent MeshComp_Scifi;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UStaticMeshComponent MeshComp_Fantasy;

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	USceneComponent MissileSpawnPoint;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AMeltdownSeekerMissile> Missile;

	AHazePlayerCharacter Target;

	UPROPERTY(EditAnywhere)
	bool bCanFire;

	UPROPERTY(EditAnywhere)
	float StartDelay = 0;

	UPROPERTY(EditAnywhere)
	float FireRate = 4;

	float TurnRate = 1;

	float TimeToFire;

	FVector MissileSpawnLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		TimeToFire = Time::GameTimeSeconds + FireRate;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bCanFire != true)
			return;

		auto Manager = ASoftSplitManager::GetSoftSplitManger();

		// Determine which player is closest for targeting
		Target = Manager.GetClosestPlayerTo(ActorLocation, GetBaseSoftSplit());
		if (Target != nullptr)
		{
			FVector TargetLocation = Manager.Position_Convert(Target.ActorCenterLocation, Manager.GetSplitForPlayer(Target), GetBaseSoftSplit());
			FVector ToTarget = TargetLocation - ActorLocation;
			SetActorRotation(ToTarget.ToOrientationQuat());

			if(TimeToFire > Time::GameTimeSeconds)
				return;

			TimeToFire = Time::GameTimeSeconds + FireRate;
			ShootMissile();
		}
	}

	void ShootMissile()
	{
		MissileSpawnLocation = MissileSpawnPoint.WorldLocation;
		SpawnActor(Missile, MissileSpawnLocation, ActorRotation);
	}

	
}