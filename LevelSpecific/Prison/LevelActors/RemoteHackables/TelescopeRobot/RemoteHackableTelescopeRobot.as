UCLASS(Abstract)
class ARemoteHackableTelescopeRobot : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	// Eman TODO: Eh, temp while we get new mesh
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SuperMeshRoot;

	UPROPERTY(DefaultComponent, Attach = SuperMeshRoot)
	UCapsuleComponent CollisionCapsule;
	default CollisionCapsule.CollisionProfileName = n"BlockAllDynamic";

	UPROPERTY(DefaultComponent, Attach = SuperMeshRoot)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent PerchRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent TelescopeRoot;

	UPROPERTY(DefaultComponent, Attach = TelescopeRoot)
	UStaticMeshComponent TelescopeMesh;

	UPROPERTY(DefaultComponent, Attach = TelescopeMesh)
	UStaticMeshComponent TelescopeMeshMiddle;
	default TelescopeMeshMiddle.bAbsoluteScale = true;

	UPROPERTY(DefaultComponent, Attach = TelescopeMeshMiddle)
	UStaticMeshComponent TelescopeMeshTip;
	default TelescopeMeshTip.bAbsoluteScale = true;

	UPROPERTY(DefaultComponent, Attach = TelescopeMesh)
	UCapsuleComponent TelescopeCollision;
	default TelescopeCollision.bAbsoluteScale = true;
	default TelescopeCollision.SetRelativeRotation(FRotator(-90, 0, 0));

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent MagneticRoot;

	UPROPERTY(DefaultComponent, Attach = SuperMeshRoot)
	URemoteHackingResponseComponent HackableComp;

	UPROPERTY(DefaultComponent, Attach = SuperMeshRoot)
	USceneComponent WheelRoot;

	UPROPERTY(DefaultComponent)
	UMagneticFieldResponseComponent MagneticFieldResponseComp;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"RemoteHackableTelescopeRobotCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"RemoteHackableTelescopeRobotEnterCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"RemoteHackableTelescopeRobotMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"RemoteHackableTelescopeRobotTelescopeCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"RemoteHackableTelescopeRobotLaunchCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"RemoteHackableTelescopeRobotIdleCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"RemoteHackableTelescopeRobotLandFlipCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"RemoteHackableTelescopeRobotBullshitNetworkLaunchCapability");

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedActorPosition;
	default SyncedActorPosition.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Player;

	UPROPERTY(EditInstanceOnly)
	ASplineActor IdleSpline;

	UPROPERTY(EditInstanceOnly)
	APerchSpline PerchSpline;

	UPROPERTY(EditInstanceOnly)
	ARemoteHackableTelescopeRobotRespawnPoint RespawnPoint;

	UPROPERTY(EditAnywhere)
	float TelescopeMaxScale = 3.5;

	bool bLaunched = false;
	bool bExtended = false;

	FTransform OriginalTransform;
	FVector Velocity;

	bool bRespawning = false;
	bool bDestroyed = false;

	bool bPlayerHackLaunching;
	FRemoteHackingLaunchEventParams PlayerHackLaunchParams;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);

		if (PerchSpline != nullptr)
		{
			PerchSpline.AttachToComponent(PerchRoot);
			PerchSpline.DisablePerchSpline(this);
		}

		TelescopeCollision.SetCapsuleRadius(TelescopeMesh.StaticMesh.BoundingBox.Extent.Y);

		HackableComp.OnLaunchStarted.AddUFunction(this, n"OnPlayerHackLaunchStarted");
		MagneticFieldResponseComp.OnBurst.AddUFunction(this, n"OnMagneticFieldBurst");

		UMovementGravitySettings::SetGravityAmount(this, 2075.0, this, EHazeSettingsPriority::Defaults);

		OriginalTransform = ActorTransform;

		OnActorBeginOverlap.AddUFunction(this, n"ActorOverlap");

		UMovementSteppingSettings::SetStepUpSize(this, FMovementSettingsValue::MakeValue(20.0), this);
	}

	// Eman TODO: Add juicy disappear VFX if robot perished without a lady inside
	UFUNCTION()
	private void ActorOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		ADeathVolume DeathVolume = Cast<ADeathVolume>(OtherActor);
		if (DeathVolume == nullptr)
			return;

		if (HackableComp.bHacked)
			return;

		if (HasControl())
			CrumbStartRespawning();
	}

	UFUNCTION()
	private void OnPlayerHackLaunchStarted(FRemoteHackingLaunchEventParams LaunchParams)
	{
		bPlayerHackLaunching = true;
		PlayerHackLaunchParams = LaunchParams;
	}

	UFUNCTION()
	private void OnMagneticFieldBurst(FMagneticFieldData Data)
	{
		// Ignore if this didn't come from magnet control
		if (!Drone::GetMagnetDronePlayer().HasControl())
			return;

		if (bRespawning)
			return;

		if (bDestroyed)
			return;

		FVector Dir = (ActorLocation - Data.ForceOrigin).ConstrainToPlane(MovementWorldUp).GetSafeNormal();
		float Dot = Dir.DotProduct(MeshRoot.ForwardVector);
		if (Dot <= 0.1)
			return;

		CrumbLaunchRobot(Data, Dir);
	}

	UFUNCTION(CrumbFunction)
	void CrumbLaunchRobot(const FMagneticFieldData& Data, FVector Direction)
	{
		FVector LaunchImpulse;
		FTelescopeRobotLandingTargetQueryResult LandingTarget;
		if (TryGetLandingTarget(Direction, LandingTarget))
		{
			// LaunchImpulse = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(ActorLocation, LandingTarget.LandingLocation, MoveComp.GravityForce, 1200);

			// Auto aim launches were super high compared to normal ones so had to do this /Zodiac
			LaunchImpulse = Trajectory::CalculateVelocityForPathWithHeight(ActorLocation, LandingTarget.LandingLocation, MoveComp.GravityForce, 400.0);
		}
		else
		{
			LaunchImpulse = (Direction * 1700.0) + MovementWorldUp * 1200.0;
		}

		SetActorVelocity(LaunchImpulse);
		bLaunched = true;
	}

	private bool TryGetLandingTarget(FVector NormalizedMagneticForce, FTelescopeRobotLandingTargetQueryResult& OutLandingTarget)
	{
		FTelescopeRobotLandingTargetQuery TargetQuery;
		TargetQuery.TelescopeRobot = this;
		TargetQuery.Direction = NormalizedMagneticForce;

		TArray<FTelescopeRobotLandingTargetQueryResult> LandingTargetCandidates;

		// Check if we can use a landing target
		TListedActors<ARemoteHackableTelescopeRobotLandingTarget> LandingTargets;
		for (auto LandingTarget : LandingTargets)
		{
			if (LandingTarget.CheckTargetable(TargetQuery))
				LandingTargetCandidates.Add(TargetQuery.Result);
		}

		// Get best candidate
		for (auto LandingTargetCandidate : LandingTargetCandidates)
		{
			if (LandingTargetCandidate.Score > OutLandingTarget.Score)
				OutLandingTarget = LandingTargetCandidate;
		}

		return OutLandingTarget.IsValid();
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartRespawning()
	{
		StartRespawning();
	}

	UFUNCTION()
	void StartRespawning()
	{
		bLaunched = false;
		bRespawning = true;

		SetActorHiddenInGame(true);

		HackableComp.SetHackingAllowed(false);
		PerchSpline.DisablePerchSpline(this);

		BP_StartRespawning();

		// Clean all relative rotations
		MeshRoot.SetRelativeRotation(FQuat::Identity);
		TelescopeMesh.SetRelativeRotation(FQuat::Identity);
		WheelRoot.SetRelativeRotation(FQuat::Identity);

		Timer::SetTimer(this, n"Respawn", 1.5);
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartRespawning() {}

	UFUNCTION()
	void Respawn()
	{
		AttachToComponent(RespawnPoint.ElevatorRoot, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
		SetActorHiddenInGame(false);
		RespawnPoint.RespawnRobot(this);
		BP_Respawn();

		MoveComp.Reset(true);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Respawn() {}

	UFUNCTION()
	void UpdateRespawnPoint(ARemoteHackableTelescopeRobotRespawnPoint NewPoint)
	{
		RespawnPoint = NewPoint;
	}

	void FinishRespawning()
	{
		DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		bRespawning = false;

		HackableComp.SetHackingAllowed(true);
	}

	void ExtendTelescope()
	{
		BP_ExtendTelescope();
	}

	void RetractTelescope()
	{
		BP_RetractTelescope();
	}

	UFUNCTION(BlueprintEvent)
	void BP_ExtendTelescope() {}

	UFUNCTION(BlueprintEvent)
	void BP_RetractTelescope() {}

	void ActivateDelayedDestroy()
	{
		if (bDestroyed)
			return;

		bDestroyed = true;

		Timer::SetTimer(this, n"DestroyTelescopeRobot", 2.0);
	}

	UFUNCTION()
	void DestroyTelescopeRobot()
	{
		HackableComp.SetHackingAllowed(false);
		BP_DestroyTelescopeRobot();
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_DestroyTelescopeRobot() {}
}