class UMoonMarketPolymorphPlayerAirDashCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Dash);
	default CapabilityTags.Add(PlayerMovementTags::AirDash);

	default CapabilityTags.Add(n"AirDash");
	default BlockExclusionTags.Add(n"MoonMarketPolymorph");

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 40;
	default TickGroupSubPlacement = 5;
	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 5, 3);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UMoonMarketShapeshiftComponent ShapeshiftComp;
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UMoonMarketPolymorphPlayerDashComponent AirDashComp;
	UPlayerAirMotionComponent AirMotionComp;
	UPlayerStepDashComponent StepDashComp;
	UPlayerStrafeComponent StrafeComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;
	UPlayerJumpComponent JumpComp;

	FVector Dir;

	FQuat StartingPlayerRotation;
	FQuat WantedPlayerRotation;
	bool bIsAutoTargeted = false;

	FVector StartPosition;
	FDashMovementCalculator DashMovementCalc;

	bool bUseCameraAmplification = false;
	const float CameraAmplificationMult = 0.3;
	float AppliedPivotOffset = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ShapeshiftComp = UMoonMarketShapeshiftComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		AirDashComp = UMoonMarketPolymorphPlayerDashComponent::Get(Player);
		AirMotionComp = UPlayerAirMotionComponent::GetOrCreate(Player);
		StepDashComp = UPlayerStepDashComponent::GetOrCreate(Player);
		StrafeComp = UPlayerStrafeComponent::GetOrCreate(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
		JumpComp = UPlayerJumpComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// Manage the camera amplification
		if (IsActive() && bUseCameraAmplification)
		{
			AppliedPivotOffset = DashMovementCalc.GetDistanceAtTime(ActiveDuration) * CameraAmplificationMult;
			UCameraSettings::GetSettings(Player).PivotOffset.ApplyAsAdditive(FVector(
				AppliedPivotOffset, 0.0, 0.0
			), this, 0.0);
		}
		else if (AppliedPivotOffset > 0.0)
		{
			AppliedPivotOffset -= Math::Max(50.0, MoveComp.HorizontalVelocity.Size() * 0.6) * DeltaTime;
			if (AppliedPivotOffset <= 0.0)
			{
				UCameraSettings::GetSettings(Player).PivotOffset.Clear(this, 0.0);
			}
			else
			{
				UCameraSettings::GetSettings(Player).PivotOffset.ApplyAsAdditive(FVector(
					AppliedPivotOffset, 0.0, 0.0
				), this, 0.0);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!ShapeshiftComp.ShapeData.bCanDash)
			return false;

		if(!ShapeshiftComp.IsShapeshiftActive())
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		if (MoveComp.IsOnWalkableGround())
			return false;

		// Don't trigger the air dash if we did a ground jump just now, wait a bit until we are actually in the air
		if (JumpComp.StartedJumpingWithinDuration(JumpComp.Settings.PostJumpAirDashCooldown))
			return false;

		// If the air dash got cancelled while it was active (for example by landing), make sure we can't
		// jump and start a new air dash immediately
		if (DeactiveDuration < AirDashComp.Settings.DashDuration)
			return false;

		//Input Buffer Window
		if (!WasActionStartedDuringTime(ActionNames::MovementDash, AirDashComp.Settings.InputBufferWindow))
		{
			if(!Accessibility::AutoJumpDash::ShouldAutoAirDash(Player))
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FAirDashDeactivationParams& Params) const
	{
		if(!ShapeshiftComp.ShapeData.bCanDash)
			return true;

		if(!ShapeshiftComp.IsShapeshiftActive())
			return true;

		if(MoveComp.HasMovedThisFrame())
			return true;

		if (DashMovementCalc.IsFinishedAtTime(ActiveDuration))
		{
			Params.bInterrupted = false;
			return true;
		}

		if (MoveComp.HasAnyValidBlockingContacts())
			return true;

		if (MoveComp.HasImpulse())
			return true;

		if (MoveComp.IsOnWalkableGround())
		{
			Params.bInterrupted = false;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::Dash, this);
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementDash);
		StartPosition = Player.ActorLocation;

		AirDashComp.StartDash();

		float DashDistance = AirDashComp.Settings.DashDistance;

		Dir = MoveComp.MovementInput.GetSafeNormal();
		if (MoveComp.MovementInput.IsNearlyZero())
			Dir = Player.ActorForwardVector;

		
		// Apply a direction constraint if we have one
		if (!AirDashComp.DirectionConstraint.IsDefaultValue())
		{
			FAirDashDirectionConstraint Constraint = AirDashComp.DirectionConstraint.Get();
			Dir = Dir.ConstrainToCone(Constraint.Direction, Constraint.MaxAngleRadians);
		}

		if (PerspectiveModeComp.IsCameraBehaviorEnabled())
		{
			bUseCameraAmplification = false;
			if (StepDashComp.bTEMP_CameraAmplification)
			{
				// Apply Camera Impulse if we're going in the forward direction of the camera,
				// we don't do this otherwise, because it will feel weird
				float ForwardDot = Dir.DotProduct(Player.ViewRotation.ForwardVector.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal());
				if (ForwardDot > 0.25)
				{
					bUseCameraAmplification = true;
				}
			}
		}

		FVector CameraDir = Player.ViewRotation.ForwardVector.ConstrainToPlane(Player.MovementWorldUp);
		StartingPlayerRotation = Player.ActorQuat;

		if (Dir.GetAngleDegreesTo(-Player.ActorForwardVector) < AirDashComp.Settings.BackwardDashAngle)
		{
			// If we're turning around too much, we always do the backwards step
			AirDashComp.DashDirection = EAirDashDirection::Backward;
			
			if (StrafeComp.IsStrafeEnabled())
			{
				WantedPlayerRotation = CameraDir.ToOrientationQuat();
			}
			else
			{
				WantedPlayerRotation = Dir.ToOrientationQuat();
			}
		}
		else if (Dir.GetAngleDegreesTo(Player.ActorForwardVector) < AirDashComp.Settings.ForwardDashAngle
			|| Dir.GetAngleDegreesTo(CameraDir) < AirDashComp.Settings.ForwardDashAngle)
		{
			AirDashComp.DashDirection = EAirDashDirection::Forward;
			WantedPlayerRotation = Dir.ToOrientationQuat();
		}
		else
		{
			// When we do a strafe, we always want to end up with our forward pointing towards the camera (or backwards)
			if (StrafeComp.IsStrafeEnabled())
			{
				if (CameraDir.DotProduct(Player.ActorForwardVector) >= 0.0)
					WantedPlayerRotation = CameraDir.ToOrientationQuat();
				else
					WantedPlayerRotation = (-CameraDir).ToOrientationQuat();
			}
			else
			{
				WantedPlayerRotation = Dir.ToOrientationQuat();
			}

			if (Dir.DotProduct(Player.ActorRightVector) >= 0.0)
				AirDashComp.DashDirection = EAirDashDirection::RightStrafe;
			else
				AirDashComp.DashDirection = EAirDashDirection::LeftStrafe;
		}

		// If we have a velocity constraint, that goes on top of the dash velocity
		FVector StartVelocity = Player.GetActorHorizontalVelocity();
		if (!AirMotionComp.VelocityConstraint.IsDefaultValue())
		{
			float DashSpeed = DashDistance / AirDashComp.Settings.DashDuration;
			StartVelocity = StartVelocity.ProjectOnToNormal(Dir).GetClampedToMaxSize(DashSpeed);
		}

		DashMovementCalc = FDashMovementCalculator(
			GetCapabilityDeltaTime(),
			DashDistance = DashDistance,
			DashDuration = AirDashComp.Settings.DashDuration,
			DashAccelerationDuration = AirDashComp.Settings.DashAccelerationDuration,
			DashDecelerationDuration = AirDashComp.Settings.DashDecelerationDuration,
			InitialSpeed = StartVelocity.Size(),
			WantedExitSpeed = AirMotionComp.Settings.HorizontalMoveSpeed + AirDashComp.Settings.DashExitOverSpeed,
		);

		Player.SetActorVerticalVelocity(FVector::ZeroVector);

		Accessibility::AutoJumpDash::StopAutoAirJumpDash(Player);
		UMoonMarketPolymorphEventHandler::Trigger_Dash_Started(ShapeshiftComp.ShapeshiftShape.CurrentShape);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FAirDashDeactivationParams Params)
	{
		AirDashComp.StopDash();

		Player.UnblockCapabilities(BlockedWhileIn::Dash, this);
		Player.ClearCameraSettingsByInstigator(this, 2.5);

		float MaxExitSpeed = DashMovementCalc.GetExitSpeed();
		if (!AirMotionComp.VelocityConstraint.IsDefaultValue())
			MaxExitSpeed += AirMotionComp.VelocityConstraint.Get().BaseVelocity.Size();

		Player.SetActorHorizontalVelocity(
			Player.ActorHorizontalVelocity.GetClampedToMaxSize(MaxExitSpeed)
		);

		UMoonMarketPolymorphEventHandler::Trigger_Dash_Stopped(ShapeshiftComp.ShapeshiftShape.CurrentShape);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				const float Alpha = Math::Saturate(ActiveDuration / AirDashComp.Settings.DashDuration);

				//Define our direction based on input and allow it to snap within timeframe.
				if (ActiveDuration < AirDashComp.Settings.RedirectionWindow && !bIsAutoTargeted)
				{
					if (!MoveComp.MovementInput.IsNearlyZero())
					{
						Dir = MoveComp.MovementInput.GetSafeNormal();
						WantedPlayerRotation = Dir.ToOrientationQuat();
					}
				}

				float FrameMovement = 0.0;
				float FrameSpeed = 0.0;

				DashMovementCalc.CalculateMovement(
					ActiveDuration, DeltaTime,
					FrameMovement, FrameSpeed
				);

				Movement.AddDeltaWithCustomVelocity(
					Dir * FrameMovement,
					Dir * FrameSpeed,
					EMovementDeltaType::Horizontal
				);

				Movement.AddDeltaWithCustomVelocity(FVector::UpVector * AirDashComp.DashVerticalSpeedCurve.GetFloatValue(Alpha) * AirDashComp.Settings.VerticalDistance * DeltaTime, FVector::ZeroVector, EMovementDeltaType::Vertical);

				// If we have a velocity constraint, that goes on top of the dash velocity
				if (!AirMotionComp.VelocityConstraint.IsDefaultValue())
					Movement.AddHorizontalVelocity(AirMotionComp.VelocityConstraint.Get().BaseVelocity);

				
				float SpinAlpha = AirDashComp.SpinSpeedCurve.GetFloatValue(Alpha);
				const float Laps = 1;
				FQuat ReferenceRot = FQuat::Slerp(StartingPlayerRotation, WantedPlayerRotation, SpinAlpha);
				FQuat TargetRot = FQuat(FVector::UpVector, PI * 2 * Laps * SpinAlpha);
				TargetRot = ReferenceRot * TargetRot;
				Movement.SetRotation(TargetRot);

				if (MoveComp.IsOnWalkableGround())
					Movement.OverrideStepDownAmountForThisFrame(54.0);

				// Apply gravity during the last bit of the air dash
				float GravityStartTimer = DashMovementCalc.GetTotalDashDuration() - AirDashComp.Settings.GravityDurationAtEnd;
				float GravityCurrentTime = ActiveDuration;
				if (GravityCurrentTime >= GravityStartTimer)
				{
					Movement.AddOwnerVerticalVelocity();
					Movement.AddGravityAcceleration();
				}
				else if (GravityCurrentTime + DeltaTime >= GravityStartTimer)
				{
					// If we activated gravity 'during' this frame, scale the acceleration we get
					float GravityDuration = GravityCurrentTime + DeltaTime - GravityStartTimer;
					Movement.AddOwnerVerticalVelocity();
					Movement.AddDeltaWithCustomVelocity(
						MoveComp.GetGravity() * GravityDuration * GravityDuration * 0.5,
						MoveComp.GetGravity() * GravityDuration,
					);
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}
			
			Movement.RequestFallingForThisFrame();
			MoveComp.ApplyMove(Movement);
		}
	}
};
