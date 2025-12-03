

enum EStepDashDirection
{
	Forward,
	LeftStrafe,
	RightStrafe,
	Backward,
}

struct FStepDashActivationParams
{
	int ChainedIndex = 0;
};

struct FStepDashDeactivationParams
{
	bool bFinished = false;
	bool bFell = false;
};

class UPlayerStepDashCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Dash);
	default CapabilityTags.Add(PlayerMovementTags::StepDash);
	default CapabilityTags.Add(PlayerStepDashTags::StepDashMovement);

	default CapabilityTags.Add(BlockedWhileIn::Perch);
	default CapabilityTags.Add(BlockedWhileIn::PerchSpline);
	default CapabilityTags.Add(BlockedWhileIn::Slide);

	default CapabilityTags.Add(n"StepDash");

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 46;
	default TickGroupSubPlacement = 2;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerStepDashComponent StepDashComp;
	UPlayerSprintComponent SprintComp;
	UPlayerStrafeComponent StrafeComp;
	UPlayerFloorMotionComponent FloorMotionComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	UPlayerPerchComponent PerchComp;

	bool bUseRotationDuration = false;
	bool bCameraSettingsActive = false;
	FVector Dir;
	FQuat StartingPlayerRotation;
	FQuat WantedPlayerRotation;
	EStepDashDirection StepDirection;
	FDashMovementCalculator DashMovementCalc;

	bool bInitiatedDuringStrafe = false;

	bool bUseCameraAmplification = false;
	float AppliedPivotOffset = 0.0;
	int ActiveChainIndex = 0;
	const float CameraAmplificationMult = 0.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		StepDashComp = UPlayerStepDashComponent::GetOrCreate(Player);
		SprintComp = UPlayerSprintComponent::GetOrCreate(Player);
		StrafeComp = UPlayerStrafeComponent::GetOrCreate(Player);
		FloorMotionComp = UPlayerFloorMotionComponent::GetOrCreate(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);

		PerchComp = UPlayerPerchComponent::Get(Player);
		DevTogglesMovement::Dash::AutoAlwaysDash.MakeVisible();
	}

	bool WasActionDashStarted() const
	{
		if (WasActionStartedDuringTime(ActionNames::MovementDash, StepDashComp.Settings.InputBufferWindow))
			return true;
#if !RELEASE
		if (DevTogglesMovement::Dash::AutoAlwaysDash.IsEnabled(Player))
			return true;
#endif
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		//tick cooldown
		if (StepDashComp.CombinedDashCooldown > 0.0)
			StepDashComp.CombinedDashCooldown -= DeltaTime;
		else
			StepDashComp.CombinedDashCooldown = 0.0;

		//Check camera setting status
		if (bCameraSettingsActive)
		{
			if (IsBlocked() || (!IsActive() && DeactiveDuration > StepDashComp.Settings.CameraSettingsLingerTime))
			{
				Player.ClearCameraSettingsByInstigator(this, 2.5);
				bCameraSettingsActive = false;
			}
		}

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
	bool ShouldActivate(FStepDashActivationParams& ActivationParams) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!MoveComp.IsOnWalkableGround())
			return false;

		if(PerchComp.GetState() != EPlayerPerchState::Inactive || PerchComp.Data.bPerching)
			return false;

		//Input Buffer Window
		if(!WasActionDashStarted())
			return false;
		
		if (StepDashComp.CombinedDashCooldown > 0.0)
			return false;

		// If the dash was timed correctly, allow it to chain boost
		float TimeSinceLastDash = Time::GetGameTimeSince(StepDashComp.LastStepDashActivation);
		if (TimeSinceLastDash >= 0.5 && TimeSinceLastDash <= 0.7)
			ActivationParams.ChainedIndex = StepDashComp.ChainedDashCount;
		else
			ActivationParams.ChainedIndex = 0;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FStepDashDeactivationParams& DeactivationParams) const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(DashMovementCalc.IsFinishedAtTime(ActiveDuration))
		{
			DeactivationParams.bFinished = true;
			return true;
		}

		if (MoveComp.HasImpulse())
			return true;

		if (!MoveComp.IsOnWalkableGround())
		{
			DeactivationParams.bFell = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FStepDashActivationParams ActivationParams)
	{
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementDash);

		StepDashComp.StartDash();
		StepDashComp.CombinedDashCooldown = StepDashComp.Settings.DashCooldown + StepDashComp.Settings.DashDuration;
		StepDashComp.bHasRolled = false;

		bInitiatedDuringStrafe = Player.IsStrafeEnabled();

		ActiveChainIndex = ActivationParams.ChainedIndex;
		StepDashComp.ChainedDashCount = (ActiveChainIndex + 1) % 3;

		Dir = MoveComp.MovementInput.GetSafeNormal();
		if (MoveComp.MovementInput.IsNearlyZero())
			Dir = Player.ActorForwardVector;

		if (PerspectiveModeComp.IsCameraBehaviorEnabled())
		{
			bCameraSettingsActive = true;

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

		if (Dir.GetAngleDegreesTo(-Player.ActorForwardVector) < StepDashComp.Settings.BackwardStepAngle)
		{
			// If we're turning around too much, we always do the backwards step
			StepDirection = EStepDashDirection::Backward;
			
			if (StrafeComp.IsStrafeEnabled())
			{
				WantedPlayerRotation = CameraDir.ToOrientationQuat();
				bUseRotationDuration = false;
			}
			else
			{
				WantedPlayerRotation = Dir.ToOrientationQuat();
				bUseRotationDuration = true;
			}
		}
		else if (Dir.GetAngleDegreesTo(Player.ActorForwardVector) < StepDashComp.Settings.ForwardStepAngle
			|| Dir.GetAngleDegreesTo(CameraDir) < StepDashComp.Settings.ForwardStepAngle)
		{
			StepDirection = EStepDashDirection::Forward;
			WantedPlayerRotation = Dir.ToOrientationQuat();
			bUseRotationDuration = false;
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
				bUseRotationDuration = false;
			}
			else
			{
				WantedPlayerRotation = Dir.ToOrientationQuat();
				bUseRotationDuration = true;
			}

			if (Dir.DotProduct(Player.ActorRightVector) >= 0.0)
				StepDirection = EStepDashDirection::RightStrafe;
			else
				StepDirection = EStepDashDirection::LeftStrafe;
		}

		StepDashComp.BS_Strafe_Direction.Y = Player.ActorForwardVector.DotProduct(Dir);
		StepDashComp.BS_Strafe_Direction.X = Player.ActorRightVector.DotProduct(Dir);

		//Set Anim Info for step direction.
		switch (StepDirection)
		{
			case EStepDashDirection::Forward:
				StepDashComp.StepDirection = EStepDashDirection::Forward;
			break;
			case EStepDashDirection::Backward:
				StepDashComp.StepDirection = EStepDashDirection::Backward;
			break;
			case EStepDashDirection::LeftStrafe:
				StepDashComp.StepDirection = EStepDashDirection::LeftStrafe;
			break;
			case EStepDashDirection::RightStrafe:
				StepDashComp.StepDirection = EStepDashDirection::RightStrafe;
			break;
		}
		
		float ExitSpeed = StepDashComp.Settings.ExitSpeed;
		if (SprintComp.IsSprintToggled())
			ExitSpeed = StepDashComp.Settings.ExitSpeedSprinting;

		float Distance = StepDashComp.Settings.StepDistance;
		float Duration = StepDashComp.Settings.DashDuration;

		switch (ActiveChainIndex)
		{
			case 1:
				Distance *= 1.3;
				Duration *= 1.1;
				ExitSpeed += 150.0;
				// SprintComp.SetSprintToggled(true);
			break;
			case 2:
				Distance *= 1.6;
				Duration *= 1.2;
				ExitSpeed += 200.0;
				// SprintComp.SetSprintToggled(true);
			break;
		}

		//Force Feedback
		if (StepDashComp.DashChainForceFeedback != nullptr && ActiveChainIndex != 0)
			Player.PlayForceFeedback(StepDashComp.DashChainForceFeedback, false, false, this);
		else if (StepDashComp.DashDefaultForceFeedback != nullptr && ActiveChainIndex == 0)
			Player.PlayForceFeedback(StepDashComp.DashDefaultForceFeedback, false, false, this);

		// PrintScaled(f"Chain Dash {ActiveChainIndex}");

		DashMovementCalc = FDashMovementCalculator(
			GetCapabilityDeltaTime(),
			DashDistance = Distance,
			DashDuration = Duration,
			DashAccelerationDuration = StepDashComp.Settings.DashAccelerationDuration,
			DashDecelerationDuration = StepDashComp.Settings.DashDecelerationDuration,
			InitialSpeed = Player.GetActorHorizontalVelocity().Size(),
			WantedExitSpeed = ExitSpeed,
		);

		Player.SetAnimTrigger(n"StartStepDash");

		UPlayerCoreMovementEffectHandler::Trigger_StepDash_Started(Player);

		Player.BlockCapabilities(BlockedWhileIn::Dash, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FStepDashDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(BlockedWhileIn::Dash, this);
		
		// Don't allow inheriting the horizontal speed from a dash when we cancel it
		Player.SetActorHorizontalVelocity(
			Player.ActorHorizontalVelocity.GetClampedToMaxSize(DashMovementCalc.GetExitSpeed())
		);

		StepDashComp.StopDash();

		UPlayerCoreMovementEffectHandler::Trigger_StepDash_Stopped(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.SetMovementFacingDirection(WantedPlayerRotation);

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				//Define our direction based on input and allow it to snap within timeframe.
				if (ActiveDuration < StepDashComp.Settings.RedirectionWindow)
				{
					if (!MoveComp.MovementInput.IsNearlyZero())
						Dir = MoveComp.MovementInput.GetSafeNormal();
				}

				float FrameMovement;
				float FrameSpeed;

				DashMovementCalc.CalculateMovement(
					ActiveDuration, DeltaTime,
					FrameMovement, FrameSpeed
				);

				Movement.AddDeltaWithCustomVelocity(
					Dir * FrameMovement,
					Dir * FrameSpeed,
					EMovementDeltaType::Horizontal
				);

				if (bUseRotationDuration)
				{
					if (StepDashComp.Settings.SideStepRotationDuration > 0.0)
					{
						Movement.SetRotation(FQuat::Slerp(
							StartingPlayerRotation, WantedPlayerRotation,
							Math::Clamp(ActiveDuration / StepDashComp.Settings.SideStepRotationDuration, 0.0, 1.0)
						));
					}
					else
					{
						Movement.SetRotation(WantedPlayerRotation);
					}
				}
				else
				{
					Movement.InterpRotationTo(WantedPlayerRotation, StepDashComp.Settings.ForwardStepRotationInterpSpeed);
				}

				if (MoveComp.IsOnWalkableGround())
					Movement.OverrideStepDownAmountForThisFrame(54.0);
				
				Movement.AddGravityAcceleration();
				Movement.AddOwnerVerticalVelocity();
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, bInitiatedDuringStrafe ? n"StrafeDash" : n"Dash");
		}
	}
};