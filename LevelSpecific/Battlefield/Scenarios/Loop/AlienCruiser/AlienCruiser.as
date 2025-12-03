event void FOnAlienCruiserUpdateSpin(float RotationSpeed);

class AAlienCruiser : AHazeActor
{
	FOnAlienCruiserUpdateSpin UpdateSpin;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent NonRotatingMeshRoot;

	UPROPERTY(DefaultComponent, Attach = NonRotatingMeshRoot)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UHazeSkeletalMeshComponentBase SkelMesh; 

	UPROPERTY(DefaultComponent)
	USceneComponent MissileOrbitRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UHazeSkeletalMeshComponentBase PreviewSkelMesh; 
	default PreviewSkelMesh.SetHiddenInGame(true);
	default PreviewSkelMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent CollisionMeshComp;
	default CollisionMeshComp.SetHiddenInGame(true);
	default CollisionMeshComp.SetCastShadow(false);

	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = "Spinner")
	USceneComponent MissileLaunchPointRoot;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TempLogTransformComp;

	UPROPERTY(DefaultComponent)
	UHazeMeshPoseDebugComponent PoseDebugComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"AlienCruiserCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"AlienCruiserMoveBackCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"AlienCruiserMoveDownCapability");

	UPROPERTY(EditAnywhere, Category = "Setuo")
	FRuntimeFloatCurve MoveBackCurve;
	default MoveBackCurve.AddDefaultKey(0.0, 0.0);
	default MoveBackCurve.AddDefaultKey(1.0, 1.0);

	/** How fast the cruiser rotates while idling */
	UPROPERTY(EditAnywhere, Category = "Rotation")
	float IdleRotationSpeed = 50.0;

	/** How fast the cruiser rotates when it starts shooting */
	UPROPERTY(EditAnywhere, Category = "Rotation")
	float ShootingRotationSpeed = 200.0;

	/** How fast it takes for the cruiser to spin up before it starts shooting */
	UPROPERTY(EditAnywhere, Category = "Delays")
	float SpinUpDuration = 2.0;

	/** How long it takes to shoot all the missiles */
	UPROPERTY(EditAnywhere, Category = "Delays")
	float ShootDuration = 2.5;

	/** How long it takes to spin down after shooing */
	UPROPERTY(EditAnywhere, Category = "Delays")
	float SpinDownDuration = 2.0;

	/** How long it takes to stop spinning after being destroyed */
	UPROPERTY(EditAnywhere, Category = "Delays")
	float StopSpinningDuration = 1.5; 

	/** How fast the missile moves forward */
	UPROPERTY(EditAnywhere, Category = "Missile")
	float MissileForwardSpeed = 3000.0;

	/** How much orbital speed the missile looses until it stops */
	UPROPERTY(EditAnywhere, Category = "Missile")
	float MissileOrbitSlowdown = 0.3;

	/** How fast the missiles initially move inwards */
	UPROPERTY(EditAnywhere, Category = "Missile")
	float MissileInwardSpeed = 0.7;

	/** At which distance the missiles stop going inwards */
	UPROPERTY(EditAnywhere, Category = "Missile")
	float MissileDistanceFromCenterTarget = 2000.0;

	/** Distance from target along forward vector that the missile starts to move towards target */
	UPROPERTY(EditAnywhere, Category = "Missile")
	float MissileDistanceFromTargetThreshold = 6000.0;

	/** Multiplier for all speeds for the missile */
	UPROPERTY(EditAnywhere, Category = "Missile")
	float MissileSpeedMultiplier = 3.0;

	/** The radius of the explosion of the missile
	 * (For response component checking) */
	UPROPERTY(EditAnywhere, Category = "Missile")
	float MissileExplosionRadius = 500.0;

	/** Whether or not the player should land on a grind. */
	UPROPERTY(EditAnywhere, Category = "KnockAway")
	bool bKnockToGrind = true;

	/** How long the knock away samples the velocity to find a location on the grind to knock the player to
	 * The higher number you have, the further ahead it will sample  */
	UPROPERTY(EditAnywhere, Category = "KnockAway", Meta = (EditCondition = bKnockToGrind, EditConditionHides))
	float KnockAwayVelocitySampleSeconds = 1.0;

	/** Distance along the platform doesn't matter, should be based on how fast you are going */
	UPROPERTY(EditAnywhere, Category = "KnockAway", Meta = (EditCondition = !bKnockToGrind, EditConditionHides))
	AActor LeftPlatformTarget;

	/** Distance along the platform doesn't matter, should be based on how fast you are going */
	UPROPERTY(EditAnywhere, Category = "KnockAway", Meta = (EditCondition = !bKnockToGrind, EditConditionHides))
	AActor RightPlatformTarget;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TSubclassOf<AAlienCruiserMissile> MissileClass;

	TOptional<AHazePlayerCharacter> PlayerGoingLeft;
	TPerPlayer<bool> HasBeenLaunched;

	FVector TargetBackLocation;
	FVector StartBackLocation;
	float BackForwardOffset = 30000.0;
	float BackUpOffset = -1500.0;

	FVector TargetDownLocation;
	FVector StartDownLocation;
	float DownUpOffset = 7000.0;
	float DownBackOffset = 2000.0;

	float CurrentRotationSpeed;

	bool bIsDestroyed = false;
	bool bShouldShoot = false;
	bool bHasShot = false;
	bool bShouldMoveBack = false;
	bool bShouldMoveDown = false;

	TArray<USceneComponent> MissileLaunchPoints;
	TArray<AAlienCruiserMissileTarget> MissileTargets;
	TArray<AAlienCruiserMissile> Missiles;

	UPROPERTY()
	float MoveDownAlpha;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MissileLaunchPointRoot.GetChildrenComponentsByClass(USceneComponent, false, MissileLaunchPoints);

		MissileTargets = TListedActors<AAlienCruiserMissileTarget>().Array;
		for(auto Target : MissileTargets)
		{
			Target.Cruiser = this;
		}

		CreateMissiles();
		SortTargetsBasedOnDistance();

		TargetBackLocation = ActorLocation;
		StartBackLocation = ActorLocation + ActorForwardVector * BackForwardOffset;
		StartBackLocation += FVector::UpVector * BackUpOffset;

		StartDownLocation = ActorLocation;
		TargetDownLocation = PreviewSkelMesh.WorldLocation;

		ActorLocation = StartBackLocation;
	}

	UFUNCTION()
	void SetToTargetBackLocation()
	{
		ActorLocation = TargetBackLocation;
	}

	UFUNCTION(CallInEditor)
	void SetPreviewLocation()
	{
		FVector TargetLoc = ActorLocation + -FVector::UpVector * DownUpOffset;
		TargetLoc -= ActorForwardVector * DownBackOffset;
		// TargetLoc += FVector(SkelMesh.RelativeLocation.X, 0.0, 0.0);
		PreviewSkelMesh.SetWorldLocation(TargetLoc);
	}

	void CreateMissiles()
	{	
		int MissileCount = MissileTargets.Num();

		for(int i = 0 ; i < MissileCount; i++)
		{
			AAlienCruiserMissile Missile = SpawnActor(MissileClass, bDeferredSpawn = true);
			Missile.AddActorDisable(this);
			Missile.MakeNetworked(this, i);
			FinishSpawningActor(Missile);
			Missiles.Add(Missile);
		}
	}

	void SortTargetsBasedOnDistance()
	{
		MissileTargets.Sort();
	}

	UFUNCTION()
	void DestroyCruiser() 
	{
		bIsDestroyed = true;
		// SetActorHiddenInGame(true);
		BP_DestroyCruiser();
		StartMovingDown();
	}

	UFUNCTION(BlueprintEvent)
	void BP_DestroyCruiser() {}

	void RotateMissileArms(float DeltaTime)
	{
		// RotationRoot.AddLocalRotation(FRotator(0, 0, CurrentRotationSpeed * DeltaTime));
		UpdateSpin.Broadcast(CurrentRotationSpeed * DeltaTime);
	}

	UFUNCTION(BlueprintCallable)
	void StartShooting()
	{
		if(bHasShot)
			return;
		bShouldShoot = true;
	}

	UFUNCTION()
	void StartMovingBack()
	{
		bShouldMoveBack = true;
	}

	void StartMovingDown()
	{
		bShouldMoveDown = true;
	}
	
	UFUNCTION()
	void SetEndState()
	{
		
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		FVector DebugStartLocation = ActorLocation + ActorForwardVector * BackForwardOffset;
		DebugStartLocation += FVector::UpVector * BackUpOffset;
		FVector DebugDownLocation = ActorLocation - FVector::UpVector * DownUpOffset;
		DebugDownLocation -= ActorForwardVector * DownBackOffset;
		Debug::DrawDebugSphere(DebugStartLocation, 5500.0, 16, FLinearColor::Red, 15.0);
		Debug::DrawDebugSphere(DebugDownLocation, 5500.0, 16, FLinearColor::Red, 15.0);
	}
#endif
}