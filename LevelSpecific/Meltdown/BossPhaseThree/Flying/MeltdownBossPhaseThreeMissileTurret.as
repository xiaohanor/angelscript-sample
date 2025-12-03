class AMeltdownBossPhaseThreeMissileTurret : AHazeActor
{
UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MissileSpawnPoint;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent PortalMesh;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AMeltdownBossPhaseThreeHomingProjectile> Missile;

	UPROPERTY()
	AHazePlayerCharacter Target;


	UPROPERTY(EditAnywhere)
	bool bCanFire;

	UPROPERTY(EditAnywhere)
	float StartDelay = 4;

	UPROPERTY(EditAnywhere)
	float FireInterval = 4;

	float TurnRate = 1;

	float TimeToFire;

	FVector MissileSpawnLocation;

	FHazeTimeLike Portal;
	default Portal.Duration = 1;
	default Portal.UseSmoothCurveZeroToOne();

	FVector StartScale;
	FVector EndScale;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TimeToFire = Time::GameTimeSeconds + FireInterval;

		Target = Game::GetMio();
		SwapPlayer();

		Portal.BindFinished(this, n"PortalOpen");
		Portal.BindUpdate(this, n"PortalOpening");

		StartScale = FVector(0.1,0.1,0.1);
		EndScale = FVector(10.0,10.0,10.0);

	}

	UFUNCTION()
	private void PortalOpening(float CurrentValue)
	{
		PortalMesh.SetRelativeScale3D(Math::Lerp(StartScale,EndScale,CurrentValue));
	}

	UFUNCTION()
	private void PortalOpen()
	{
		if(Portal.IsReversed())
		{
		PortalMesh.SetHiddenInGame(true);
		return;
		}
		
		Portal.Reverse();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bCanFire != true)
			return;

		FVector ToTarget = Target.ActorCenterLocation - ActorLocation;

		SetActorRotation(ToTarget.ToOrientationQuat());


		if(TimeToFire > Time::GameTimeSeconds)
			return;

		TimeToFire = Time::GameTimeSeconds + FireInterval;
		Portal.Play();
		PortalMesh.SetHiddenInGame(false);
		Timer::SetTimer(this, n"ShootMissile", 1.0);


	}

	UFUNCTION()
	private void SwapPlayer()
	{
		Target = Target.OtherPlayer;

		Timer::SetTimer(this, n"SwapPlayer", 7.0);
	}

	UFUNCTION(BlueprintCallable)
	void ShootMissile()
	{
		MissileSpawnLocation = MissileSpawnPoint.WorldLocation;
		AMeltdownBossPhaseThreeHomingProjectile SpawnedActor = SpawnActor(Missile,MissileSpawnLocation, ActorRotation);

		SpawnedActor.Launch(Target);
	}

};