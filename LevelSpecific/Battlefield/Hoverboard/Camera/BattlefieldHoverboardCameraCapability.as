class UBattlefieldHoverboardCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(CameraTags::CameraControl);
	default CapabilityTags.Add(BattlefieldHoverboardCapabilityTags::Hoverboard);

	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::StickInput);

	default DebugCategory = n"Hoverboard";

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 1;

	UBattlefieldHoverboardComponent HoverboardComp;
	UBattlefieldHoverboardJumpComponent JumpComp;
	UBattlefieldHoverboardFreeFallingComponent FreeFallComp;
	UBattlefieldHoverboardLoopComponent HoverboardLoopComp;
	UPlayerMovementComponent MoveComp;
	UCameraUserComponent CameraUser;

	UBattlefieldHoverboardCameraControlSettings CameraControlSettings;

	FHazeAcceleratedFloat AccCameraVelocityFollowPitch;
	FHazeAcceleratedRotator AccSteeringCameraRotation;
	FHazeAcceleratedRotator AccInputCameraRotation;

	float NoCameraInputTimer = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		JumpComp = UBattlefieldHoverboardJumpComponent::Get(Player);
		CameraUser = UCameraUserComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		FreeFallComp = UBattlefieldHoverboardFreeFallingComponent::Get(Player);
		HoverboardLoopComp = UBattlefieldHoverboardLoopComponent::Get(Player);

		CameraControlSettings = UBattlefieldHoverboardCameraControlSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!CameraUser.CanControlCamera())
			return false;

		if(FreeFallComp.bIsFreeFalling)
			return false;

		if(Player.HasActivePointOfInterest(UHazePointOfInterestBase))
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!CameraUser.CanControlCamera())
			return true;

		if(FreeFallComp.bIsFreeFalling)
			return true;

		if(Player.HasActivePointOfInterest(UHazePointOfInterestBase))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FRotator CameraControlRotation = CameraUser.GetControlRotation();
		AccCameraVelocityFollowPitch.SnapTo(CameraControlRotation.Pitch);
		CameraControlRotation.Roll = 0;
		CameraControlRotation.Pitch = 0;
		AccSteeringCameraRotation.SnapTo(CameraControlRotation, CameraUser.ViewVelocity.Rotation());
		AccInputCameraRotation.SnapTo(FRotator::ZeroRotator);
		NoCameraInputTimer = 0.0;

		TEMPORAL_LOG(Player, "Hoverboard Camera")
			.Rotation("Camera Control Rotation", CameraUser.GetControlRotation(), Player.ActorLocation, 500)
		;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
			return;

		if(CameraUser.CanApplyUserInput())
		{
			const float CameraDeltaTime = Time::CameraDeltaSeconds;

			FHitResult GroundHit = TraceForGround();
			float VelocityPitchTarget = GetVelocityPitchTarget(GroundHit);

			AccCameraVelocityFollowPitch.AccelerateTo(VelocityPitchTarget, CameraControlSettings.VelocityPitchInterpDuration, DeltaTime);

			FRotator SteeringCameraTarget = HoverboardComp.CameraWantedRotation;
			AccSteeringCameraRotation.AccelerateTo(SteeringCameraTarget, CameraControlSettings.RotationDuration, CameraDeltaTime);
			
			UpdateInputRotation(CameraDeltaTime);

			FRotator CameraRotation = AccSteeringCameraRotation.Value;
			CameraRotation.Pitch = AccCameraVelocityFollowPitch.Value;
			CameraRotation += AccInputCameraRotation.Value;

			FRotator DeltaRotation = CameraRotation - CameraUser.GetActiveCameraRotation();

			CameraUser.AddUserInputDeltaRotation(DeltaRotation, this);

			TEMPORAL_LOG(Player, "Hoverboard Camera")
				.Rotation("Steering Camera Rotation", AccSteeringCameraRotation.Value, Player.ActorLocation, 500)
				.Value("Velocity Follow Pitch", AccCameraVelocityFollowPitch.Value)
				.Rotation("Input Camera Rotation", AccInputCameraRotation.Value, Player.ActorLocation, 500)
				.Rotation("Camera Rotation", CameraRotation, Player.ActorLocation, 500)
			;

			if(MoveComp.IsOnAnyGround()
			&& MoveComp.WasInAir())
			{
				ApplyLandingImpulse();
			}
		}
	}

	private void UpdateInputRotation(float DeltaTime)
	{
		FVector2D CameraInputRaw = Player.GetCameraInput();
		FRotator TargetInputRotation = FRotator::ZeroRotator;
		float RotationDuration;
		
		if(CameraInputRaw.IsNearlyZero())
		{
			NoCameraInputTimer += DeltaTime;
			if(NoCameraInputTimer < CameraControlSettings.NoInputRotateBackDelay)
			{
				AccInputCameraRotation.Velocity = FRotator::ZeroRotator;
				return;
			}

			RotationDuration = CameraControlSettings.NoInputRotateBackDuration;
		}
		else
		{
			NoCameraInputTimer = 0.0;
			TargetInputRotation.Pitch += CameraControlSettings.InputRotationMax.Pitch * CameraInputRaw.Y;
			TargetInputRotation.Yaw += CameraControlSettings.InputRotationMax.Yaw * CameraInputRaw.X;
			RotationDuration = CameraControlSettings.RotationDuration;
		}
		AccInputCameraRotation.AccelerateTo(TargetInputRotation, RotationDuration, DeltaTime);
	}

	private FHitResult TraceForGround() const
	{
		FHazeTraceSettings Trace;
		Trace.TraceWithPlayer(Player);
		Trace.UseLine();

		FVector Start = Player.ActorLocation;
		FVector End = Player.ActorLocation + FVector::DownVector * CameraControlSettings.VelocityPitchGroundTraceDistance;

		FHitResult Hit = Trace.QueryTraceSingle(Start, End);
		TEMPORAL_LOG(HoverboardComp)
		.HitResults("Camera Velocity Pitch Ground Trace", Hit, FHazeTraceShape::MakeLine())
		;

		return Hit;
	}

	private float GetVelocityPitchTarget(FHitResult GroundHit) const
	{
		FVector ActorVelocity = Player.ActorVelocity;
		float VelocityPitchTarget = ActorVelocity.Rotation().Pitch;

		float MinPitch = CameraControlSettings.VelocityPitchMin;
		float MaxPitch = CameraControlSettings.VelocityPitchMax;

		if(GroundHit.bBlockingHit)
		{
			FVector ForwardProjectedOntoNormal = Player.ActorForwardVector.VectorPlaneProject(GroundHit.ImpactNormal);
			FRotator GroundRotation = FRotator::MakeFromXZ(ForwardProjectedOntoNormal, GroundHit.ImpactNormal);
			if(JumpComp.bAirborneFromJump)
				VelocityPitchTarget = GroundRotation.Pitch;

			MinPitch += GroundRotation.Pitch;
			MaxPitch += GroundRotation.Pitch;
		}

		return Math::Clamp(VelocityPitchTarget, MinPitch, MaxPitch);
	}

	private void ApplyLandingImpulse()
	{
		if(HoverboardLoopComp.bIsInLoop)
			return;

		float SpeedAlignedWithGround = MoveComp.PreviousVelocity.DotProduct(MoveComp.CurrentGroundNormal);
		SpeedAlignedWithGround = Math::Clamp(SpeedAlignedWithGround, -CameraControlSettings.LandingImpulseMaxSize, CameraControlSettings.LandingImpulseMaxSize);

		FHazeCameraImpulse CamImpulse;
		CamImpulse.WorldSpaceImpulse = MoveComp.CurrentGroundNormal * SpeedAlignedWithGround * CameraControlSettings.LandingImpulseMultiplier;
		CamImpulse.ExpirationForce = CameraControlSettings.LandingImpulseExpirationForce;
		CamImpulse.Dampening = 1.0;
		Player.ApplyCameraImpulse(CamImpulse, this);

		TEMPORAL_LOG(Player, "HoverboardCamera")
			.Value("Speed Aligned With Up", SpeedAlignedWithGround)
		;
	}

};