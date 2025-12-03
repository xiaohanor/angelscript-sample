/**
 * 
 */
class USketchbookBowAimCapability : UHazePlayerCapability
{
    default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
   	default DebugCategory = Sketchbook::Bow::DebugCategory;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;
    
    default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(Sketchbook::Bow::SketchbookBow);

	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);
	default CapabilityTags.Add(BlockedWhileIn::Crouch);
	default CapabilityTags.Add(BlockedWhileIn::DashRollState);
	default CapabilityTags.Add(BlockedWhileIn::AirJump);

	USketchbookBowPlayerComponent BowComp;

    float AimDelay = 4;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        BowComp = USketchbookBowPlayerComponent::Get(Player);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
		if(BowComp.IsCharging())
			return true;

        if(GetAttributeVector2D(AttributeVectorNames::RightStickRaw).IsNearlyZero())
            return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
		if(BowComp.IsCharging())
			return false;

        if(GetAttributeVector2D(AttributeVectorNames::RightStickRaw).IsNearlyZero())
            return true;

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated()
    {
        Player.BlockCapabilities(PlayerMovementTags::WallRun, this);
        Player.BlockCapabilities(PlayerMovementTags::LedgeGrab, this);
        Player.BlockCapabilities(PlayerMovementTags::WallScramble, this);

        BowComp.AimComp.StartAiming(BowComp, BowComp.BowSettings.AimSettings);

        USketchbookBowPlayerEventHandler::Trigger_StartAiming(Player);

        BowComp.bIsAimingBow = true;
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated()
    {
        Player.UnblockCapabilities(PlayerMovementTags::WallRun, this);
        Player.UnblockCapabilities(PlayerMovementTags::LedgeGrab, this);
        Player.UnblockCapabilities(PlayerMovementTags::WallScramble, this);

        BowComp.AimComp.StopAiming(BowComp);
		BowComp.AimTrajectorySpline = FHazeRuntimeSpline();

        USketchbookBowPlayerEventHandler::Trigger_StopAiming(Player);
		
        BowComp.bIsAimingBow = false;
        BowComp.SetChargeFactor(0.0);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		if(!Player.Mesh.CanRequestOverrideFeature())
            return;

		// Updated aim result since player can still move aim while waiting to shoot
        // FAimingResult AimResult = BowComp.AimComp.GetAimingTarget(BowComp);

		// FVector FacingDir = AimResult.AimDirection.ConstrainToPlane(Player.MovementWorldUp).GetSafeNormal(ResultIfZero = Player.ActorForwardVector);
        // Player.SetMovementFacingDirection(FacingDir);
        Player.Mesh.RequestOverrideFeature(Sketchbook::Bow::Feature, this);



		SimulateLaunch();
    }

	void SimulateLaunch()
	{
		float Time = 0;
		int Iteration = 0;
		const float TimeStep = 1.0 / 10;
		const float Duration = 10;

		float InitialSpeed = BowComp.ArrowSettings.MaxLaunchSpeed;
		float InitialGravity = BowComp.ArrowSettings.MaxChargeGravity;

		if(BowComp.IsCharging() && !BowComp.IsFiring())
		{
			InitialSpeed = BowComp.GetArrowSpeed();
			InitialGravity = BowComp.GetArrowGravity();
		}

        const FAimingResult AimResult = BowComp.AimComp.GetAimingTarget(BowComp);

		FVector InitialLocation = BowComp.GetArrowSpawnLocation();

		// if(BowComp.bUseFire)
		// {
		// 	float XPos = TListedActors<ASketchbookDarkCaveShader>().Single.ActorLocation.X - 20;
		// 	InitialLocation.X += XPos;
		// }

		const FVector InitialVelocity = AimResult.AimDirection * InitialSpeed;

		BowComp.AimTrajectorySpline = FHazeRuntimeSpline();
		BowComp.AimTrajectorySpline.AddPoint(InitialLocation);
		BowComp.AimTrajectorySpline.SetCustomEnterTangentPoint(InitialVelocity);

		FTraversalTrajectory Trajectory;
		Trajectory.LaunchLocation = InitialLocation;
		Trajectory.LaunchVelocity = InitialVelocity;
		Trajectory.Gravity = FVector::DownVector * InitialGravity;

		while(Time < Duration)
		{
			FVector PreviousLocation = Trajectory.GetLocation(Time);
			Time += TimeStep;
			FVector NewLocation = Trajectory.GetLocation(Time);

			//Debug::DrawDebugLine(PreviousLocation, NewLocation, FLinearColor::Black, 1);

			FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			TraceSettings.IgnorePlayers();
			TraceSettings.UseLine();
			FHitResult Hit = TraceSettings.QueryTraceSingle(PreviousLocation, NewLocation);

			if(Hit.IsValidBlockingHit())
			{
				//Debug::DrawDebugSphere(Hit.Location, 10, 18, FLinearColor::Black, 0.5);
				BowComp.AimTrajectorySpline.AddPoint(Hit.ImpactPoint);
				BowComp.AimTrajectorySpline.SetCustomExitTangentPoint(Trajectory.GetVelocity(Time));
				break;
			}

			BowComp.AimTrajectorySpline.AddPoint(NewLocation);

			Iteration++;
		}

		if(BowComp.IsCharging())
		{
			// FDebugDrawRuntimeSplineParams Param = FDebugDrawRuntimeSplineParams();
			// Param.LineColor = FLinearColor(1,1,1,1);
			// Param.bDrawMovingPoint = false;
			// Param.bDrawEndPoint = false;
			// Param.bDrawStartPoint = false;
			// Param.Width = 0.25;
			// Param.NumSegments = 1000;
			// Param.bDrawSplinePoints = false;
			// Param.bDrawInForeground = true;
			// BowComp.AimTrajectorySpline.DrawDebugSpline(Param);
		}
		
	}
};