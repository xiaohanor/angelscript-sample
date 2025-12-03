class ATazerBot : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeOffsetComponent MeshOffsetComponent;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UPoseableMeshComponent MeshComponent;
	default MeshComponent.bComponentUseFixedSkelBounds = true;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UCapsuleComponent CapsuleCollider;
	default CapsuleCollider.SetCollisionResponseToChannel(ECollisionChannel::PlayerAbilityZoe, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = MeshComponent, AttachSocket = "Tazer3")
	UCapsuleComponent SocketCollider;

	// Used for friendly fire
	UPROPERTY(DefaultComponent, Attach = MeshComponent, AttachSocket = "Tazer3")
	UCapsuleComponent PlayerTipCollider;

	// Used for friendly fire
	UPROPERTY(DefaultComponent, Attach = MeshComponent, AttachSocket = "Tazer3")
	UCapsuleComponent PlayerTelescopeCollision;
	default PlayerTelescopeCollision.bAbsoluteScale = true;

	UPROPERTY(DefaultComponent, Attach = MeshComponent, AttachSocket = "Head")
	UCapsuleComponent TurretPlayerCollider;

	UPROPERTY(DefaultComponent, Attach = MeshComponent, AttachSocket = "Base")
	UCapsuleComponent BaseColliderLeft;

	UPROPERTY(DefaultComponent, Attach = MeshComponent, AttachSocket = "Base")
	UCapsuleComponent BaseColliderRight;

	UPROPERTY(DefaultComponent, Attach = MeshComponent, AttachSocket = "Head")
	USceneComponent PerchRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USpringArmCamera CameraComp;

	UPROPERTY(DefaultComponent, Attach = MeshComponent, AttachSocket = "Head")
	USceneComponent TutorialAttachComp;

	UPROPERTY(Category = "Camera|Launch")
	UHazeCameraSpringArmSettingsDataAsset LaunchCameraSettings;

	UPROPERTY(Category = "Camera|Launch")
	TSubclassOf<UCameraShakeBase> LaunchTumbleCamShake;

	UPROPERTY(Category = "Camera|Launch")
	TSubclassOf<UCameraShakeBase> LaunchLandingCamShake;

	UPROPERTY(Category = "FF|Launch")
	UForceFeedbackEffect LaunchLandingFF;

	UPROPERTY(Category = "FF")
	UForceFeedbackEffect KnockdownFF;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComponent;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComponent;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent CrumbComponent;
	default CrumbComponent.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Character;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent CrumbedAngularSpeed;
	default CrumbedAngularSpeed.OverrideSyncRate(EHazeCrumbSyncRate::High);

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultCapabilities.Add(n"TazerBotControlCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"TazerBotMovementCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"TazerBotAirMovementCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"TazerBotTelescopeCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"TazerBotLaunchCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"TazerBotLaunchBullshitNetworkCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"TazerBotPlayerEnterCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"TazerBotFriendlyFireCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"TazerBotIdleMovementCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"TazerBotSocketCapability");

	UPROPERTY(DefaultComponent, Attach = MeshRoot, BlueprintReadWrite)
	private URemoteHackingResponseComponent RemoteHackableComponent;

	UPROPERTY(DefaultComponent)
	private UMagneticFieldResponseComponent MagneticResponseComponent;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 8000;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.PlayerCapabilityClasses.Add(UTazerBotPerchWallImpactCapability);

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY(EditInstanceOnly)
	private APerchSpline PerchSpline;
	bool bPerchSplineEnabled = false;

	UPROPERTY(EditInstanceOnly)
	ATazerBotRespawnPoint RespawnPoint;

	UPROPERTY(EditAnywhere, Category = "Player Trolling")
	FTazerBotKnockdownParams KnockdownParams;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> KnockdownCamShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect KnockDownFF;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> PlayerZapDeathEffect;

	UPROPERTY(NotEditable, BlueprintHidden, Transient)
	UMaterialInstanceDynamic TracksMaterialInstance = nullptr;

	UPROPERTY(EditDefaultsOnly, Category = "TelescopeCollision")
	FTazerBotTelescopeCollisionData TelescopeCollisionData;

	UPROPERTY(EditDefaultsOnly, Category = "Perch Wall Impact")
	float PerchWallImpactMovementSpeedThreshold = 50;

	UPROPERTY(EditDefaultsOnly, Category = "Perch Wall Impact")
	float PerchWallImpactAngularSpeedThreshold = 0.1;


	UTazerBotSettings Settings;

	FRemoteHackingLaunchEventParams PlayerHackLaunchParams;

	access TelescopeCapability = private, UTazerBotTelescopeCapability;
	access : TelescopeCapability float RodExtensionFraction = 0.0;

	access LaunchCapability = private, UTazerBotLaunchCapability, UTazerBotLaunchBullshitNetworkCapability;
	access : LaunchCapability FTazerBotLaunchParams CurrentLaunchParams;

	bool bPlayerHackLaunching = false;
	bool bTelescopeTutorialCompleted = false;
	bool bLaunched = false;
	bool bExtended = false;
	bool bRespawning = false;
	bool bDestroyed = false;

	ATazerBotSocket CurrentSocket;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovementComponent.SetupShapeComponent(CapsuleCollider);

		SetActorControlSide(Game::Mio);

		Settings = UTazerBotSettings::GetSettings(this);

		// Setup perch spline
		if (PerchSpline != nullptr)
		{
			PerchSpline.AttachToComponent(PerchRoot, NAME_None, EAttachmentRule::SnapToTarget);
			PerchSpline.DisablePerchSpline(this);
			PerchSpline.DisablePerchSplineForPlayer(Drone::GetSwarmDronePlayer(), this);
		}

		// Ok, this is a bit weird... but in order for the whole bone animation system to work,
		// their root rotation needs always be world zero. This is enforced in movement capability.
		MeshRoot.SetRelativeRotation(ActorQuat.Inverse());
		MeshComponent.SetBoneRotationByName(n"Base", ActorRotation, EBoneSpaces::WorldSpace);
		MeshComponent.SetBoneRotationByName(n"Head", ActorRotation, EBoneSpaces::WorldSpace);

		// Setup delegates
		RemoteHackableComponent.OnLaunchStarted.AddUFunction(this, n"OnPlayerHackLaunchStarted");
		RemoteHackableComponent.OnHackingStopped.AddUFunction(this, n"HackingStopped");
		MagneticResponseComponent.OnBurst.AddUFunction(this, n"OnMagneticFieldBurst");
		OnActorBeginOverlap.AddUFunction(this, n"OnActorOverlap");

		// Movement stuff
		UMovementGravitySettings::SetGravityAmount(this, 2300.0, this, EHazeSettingsPriority::Defaults);
		UMovementSteppingSettings::SetStepUpSize(this, FMovementSettingsValue::MakeValue(20.0), this);

		Timer::SetTimer(this, n"DelayedPerchSplineDisable", 0.5);

		// Create material instance from tracks
		TracksMaterialInstance = MeshComponent.CreateDynamicMaterialInstance(0);
		MeshComponent.SetMaterial(0, TracksMaterialInstance);
	}

	UFUNCTION()
	private void HackingStopped()
	{
		if (!HasActorBegunPlay())
			return;

		FVector LaunchDir = MeshComponent.GetBoneRotationByName(n"Head", EBoneSpaces::WorldSpace).ForwardVector;
		HackingPlayer.SmoothTeleportActor(Game::Mio.ActorLocation + (FVector::UpVector * 100.0), LaunchDir.Rotation(), this, 0.1);

		FVector LaunchImpulse = LaunchDir * -400.0;
		LaunchImpulse += FVector::UpVector * 400.0;
		HackingPlayer.AddMovementImpulse(LaunchImpulse);
	}

	UFUNCTION()
	void DelayedPerchSplineDisable()
	{
		SetPerchSplineEnabled(false);
	}

	UFUNCTION()
	void SetPerchSplineEnabled(bool bValue)
	{
		if (PerchSpline != nullptr)
		{
			if (bValue)
				PerchSpline.EnablePerchSpline(this);
			else
				PerchSpline.DisablePerchSpline(this);

			bPerchSplineEnabled = bValue;
		}
	}

	void UpdateWorldSplinePoints(FVector WorldStartLocation, FVector WorldEndLocation)
	{
		FVector RelativeStartLocation = PerchRoot.WorldTransform.InverseTransformPosition(WorldStartLocation);
		FVector RelativeEndLocation = PerchRoot.WorldTransform.InverseTransformPosition(WorldEndLocation);

		UpdateRelativeSplinePoints(RelativeStartLocation, RelativeEndLocation);
	}

	void UpdateRelativeSplinePoints(FVector RelativeStartLocation, FVector RelativeEndLocation)
	{
		// Also need to update start to follow turret rotation
		PerchSpline.Spline.SplinePoints[0].RelativeLocation = RelativeStartLocation;
		PerchSpline.Spline.SplinePoints.Last().RelativeLocation = RelativeEndLocation;
		PerchSpline.Spline.UpdateSpline();
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnActorOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		ADeathVolume DeathVolume = Cast<ADeathVolume>(OtherActor);
		if (DeathVolume == nullptr)
			return;

		if (IsHacked())
		{
			// Magnet murder!
			if (bLaunched && HasControl())
				CrumbKilledByMagnetPlayer();

			return;
		}

		if (HasControl())
			CrumbStartRespawning();

		// Eman TODO: Add juicy disappear VFX if robot perished without a lady inside
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerHackLaunchStarted(FRemoteHackingLaunchEventParams LaunchParams)
	{
		bPlayerHackLaunching = true;
		PlayerHackLaunchParams = LaunchParams;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnMagneticFieldBurst(FMagneticFieldData Data)
	{
		// Ignore if this didn't come from magnet control
		if (!Drone::GetMagnetDronePlayer().HasControl())
			return;

		if (bRespawning)
			return;

		if (bDestroyed)
			return;

		FVector Direction = (ActorLocation - Data.ForceOrigin).ConstrainToPlane(MovementWorldUp).GetSafeNormal();
		FRotator TurretRotation = MeshComponent.GetBoneRotationByName(n"Head", EBoneSpaces::WorldSpace);
		float MagnetAlignment = Direction.DotProduct(TurretRotation.ForwardVector.ConstrainToPlane(MovementWorldUp));
		if (MagnetAlignment <= 0.1)
			return;

		CrumbLaunchRobot(Data, Direction);
	}

	UFUNCTION(CrumbFunction)
	void CrumbLaunchRobot(const FMagneticFieldData& Data, FVector Direction)
	{
		CurrentLaunchParams = FTazerBotLaunchParams();

		FTazerBotLandingTargetQueryResult LandingTarget;
		if (TazerBot::TryGetLandingTarget(this, Direction, LandingTarget))
		{
			// LaunchParams.Impulse = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(ActorLocation, LandingTarget.LandingLocation, MoveComp.GravityForce, 1200);

			Trajectory::FOutCalculateVelocity TrajectoryParams = Trajectory::CalculateParamsForPathWithHeight(ActorLocation, LandingTarget.LandingLocation, MovementComponent.GravityForce, 400.0);
			CurrentLaunchParams.TargetLocation = LandingTarget.LandingLocation;
			CurrentLaunchParams.Impulse = TrajectoryParams.Velocity;
			CurrentLaunchParams.Time = TrajectoryParams.Time;
		}
		else
		{
			CurrentLaunchParams.Impulse = (Direction * 1700.0) + MovementWorldUp * 1200.0;
			CurrentLaunchParams.GenerateRandomTorque();
		}

		bLaunched = true;
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartRespawning()
	{
		StartRespawning();
	}

	UFUNCTION(CrumbFunction)
	void CrumbKilledByMagnetPlayer()
	{
		UTazerBotEventHandler::Trigger_OnKilledByMagnetPlayer(this);
	}

	UFUNCTION()
	void StartRespawning()
	{
		bLaunched = false;
		bRespawning = true;

		SetActorHiddenInGame(true);

		SetActorEnableCollision(false);
		RemoteHackableComponent.SetHackingAllowed(false);
		PerchSpline.DisablePerchSpline(this);

		BP_StartRespawning();

		// Clean all relative rotations
		MeshRoot.SetRelativeRotation(FQuat::Identity);

		// Eman TODO:
		// TelescopeMesh.SetRelativeRotation(FQuat::Identity);
		// WheelRoot.SetRelativeRotation(FQuat::Identity);

		Timer::SetTimer(this, n"Respawn", 1.5);

		UTazerBotEventHandler::Trigger_OnDestroyed(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartRespawning() {}

	UFUNCTION()
	void Respawn()
	{
		AttachToComponent(RespawnPoint.BotAttachComp, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
		MeshComponent.SetBoneRotationByName(n"Base", ActorRotation, EBoneSpaces::WorldSpace);
		MeshComponent.SetBoneRotationByName(n"Head", ActorRotation, EBoneSpaces::WorldSpace);

		MeshRoot.ResetRelativeTransform();

		SetActorHiddenInGame(false);
		SetActorEnableCollision(true);

		RespawnPoint.RespawnRobot(this);
		BP_Respawn();

		MovementComponent.Reset(true);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Respawn() {}

	void FinishRespawning()
	{
		DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		bRespawning = false;

		RemoteHackableComponent.SetHackingAllowed(true);
	}

	UFUNCTION()
	void UpdateRespawnPoint(ATazerBotRespawnPoint NewPoint)
	{
		RespawnPoint = NewPoint;
	}

	UFUNCTION()
	void SetHackingAllowed(bool bValue)
	{
		RemoteHackableComponent.SetHackingAllowed(bValue);
	}

	UFUNCTION(BlueprintPure)
	bool IsHacked() const
	{
		return RemoteHackableComponent.bHacked;
	}

	UFUNCTION()
	AHazePlayerCharacter GetHackingPlayer() const property
	{
		return RemoteHackableComponent.HackingPlayer;
	}

	UFUNCTION(BlueprintPure)
	bool IsLaunched() const
	{
		return bLaunched;
	}

	bool IsAirborne() const
	{
		return MovementComponent.IsInAir();
	}

	UFUNCTION(BlueprintPure)
	float GetRodExtensionFraction() const
	{
		return RodExtensionFraction;
	}

	void ActivateDelayedDestroy(ATazerBotSocket Socket)
	{
		if (bDestroyed)
			return;

		CurrentSocket = Socket;
		bDestroyed = true;

		// Timer::SetTimer(this, n"OnDestroyTimer", 2.0);
	}

	FVector GetTurretForwardVector(bool bIgnorePitch) const
	{
		FTransform TurretTransform = MeshComponent.GetBoneTransformByName(n"Head", EBoneSpaces::WorldSpace);
		FRotator TurretRotation = TurretTransform.Rotator();

		// We don't want tazer rod to pitch or roll
		if (bIgnorePitch)
			TurretRotation.Pitch = TurretRotation.Roll = 0;

		return TurretRotation.Vector();
	}

	
	UFUNCTION(BlueprintPure)
	bool IsPlayePerchingOnTelescope(AHazePlayerCharacter Player) const
	{
		UPlayerPerchComponent PlayerPerchComponent = UPlayerPerchComponent::Get(Player);
		if (PlayerPerchComponent == nullptr)
			return false;

		if (!PlayerPerchComponent.IsCurrentlyPerching())
			return false;

		if (PerchSpline != PlayerPerchComponent.Data.ActiveSpline)
			return false;

		return true;
	}

	UFUNCTION()
	private void OnDestroyTimer()
	{
		RemoteHackableComponent.SetHackingAllowed(false);
		BP_OnDestroyed();
		AddActorDisable(this);

		UTazerBotEventHandler::Trigger_OnDestroyed(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnDestroyed() { }
}