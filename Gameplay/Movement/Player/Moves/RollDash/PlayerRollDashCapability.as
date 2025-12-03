struct FRollDashDeactivationParams
{
	bool bFinished = false;
	bool bFell = false;
};

class UPlayerRollDashCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Dash);
	default CapabilityTags.Add(PlayerMovementTags::RollDash);
	default CapabilityTags.Add(PlayerRollDashTags::RollDashMovement);

	default CapabilityTags.Add(BlockedWhileIn::Perch);
	default CapabilityTags.Add(BlockedWhileIn::PerchSpline);
	default CapabilityTags.Add(BlockedWhileIn::Slide);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 46;
	default TickGroupSubPlacement = 1;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerStepDashComponent StepDashComp;
	UPlayerRollDashComponent RollDashComp;
	UPlayerSprintComponent SprintComp;
	UPlayerJumpComponent JumpComp;
	UPlayerFloorMotionComponent FloorMotionComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;
	UPlayerStrafeComponent StrafeComp;

	UPlayerPerchComponent PerchComp;

	FVector Dir;
	FQuat WantedPlayerRotation;

	FDashMovementCalculator DashMovementCalc;
	FVector StartPos;

	bool bInRollState = false;
	bool bRollDashBuffered = false;

	float RollStateRemainingTime = 0.0;

	bool bUseCameraAmplification = false;
	const float CameraAmplificationMult = 0.3;
	float AppliedPivotOffset = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		StepDashComp = UPlayerStepDashComponent::GetOrCreate(Player);
		RollDashComp = UPlayerRollDashComponent::GetOrCreate(Player);
		SprintComp = UPlayerSprintComponent::GetOrCreate(Player);
		JumpComp = UPlayerJumpComponent::GetOrCreate(Player);
		FloorMotionComp = UPlayerFloorMotionComponent::GetOrCreate(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
		StrafeComp = UPlayerStrafeComponent::Get(Player);

		PerchComp = UPlayerPerchComponent::Get(Player);
		DevTogglesMovement::Dash::AutoAlwaysDash.MakeVisible();
	}

	bool WasActionDashStarted() const
	{
		if (WasActionStarted(ActionNames::MovementDash))
			return true;
#if !RELEASE
		if (DevTogglesMovement::Dash::AutoAlwaysDash.IsEnabled(Player))
			return true;
#endif
		return false;
	}

	void EnterRollState()
	{
		RollStateRemainingTime = RollDashComp.Settings.BlockedRollStateDuration;
		if (!bInRollState)
		{
			bInRollState = true;
			Player.BlockCapabilities(BlockedWhileIn::DashRollState, this);
		}
	}

	void ExitRollState()
	{
		if (bInRollState)
		{
			bInRollState = false;
			Player.UnblockCapabilities(BlockedWhileIn::DashRollState, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// Check if our roll state is over and we should unblock jump etc
		if (bInRollState)
		{
			RollStateRemainingTime -= DeltaTime;
			if (RollStateRemainingTime <= 0.0)
				ExitRollState();
		}
		
		// See if we should buffer a roll dash
		if (!IsBlocked() && !IsActive() && !StepDashComp.bHasRolled)
		{
			if (WasActionDashStarted() && Time::GetGameTimeSince(StepDashComp.LastStepDashActivation) <= RollDashComp.Settings.BufferUntilTimeAfterStep)
			{
				bRollDashBuffered = true;
			}
		}
		else
		{
			bRollDashBuffered = false;
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
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!MoveComp.IsOnWalkableGround())
			return false;

		const float TimeSinceStepDash = Time::GetGameTimeSince(StepDashComp.LastStepDashActivation);
		const bool bTimedAfterStepDash = TimeSinceStepDash <= RollDashComp.Settings.MaxAvailableTimeAfterStep
			&& TimeSinceStepDash >= RollDashComp.Settings.BufferUntilTimeAfterStep;

		if (bTimedAfterStepDash)
		{
			if (WasActionDashStarted() || bRollDashBuffered)
				return true;
		}

		const bool ALLOW_ROLL_AFTER_LANDING = true;
		if (ALLOW_ROLL_AFTER_LANDING)
		{
			const bool bTimedAfterLanding = Time::GetGameTimeSince(FloorMotionComp.LastLandedTime) < 0.1 || MoveComp.WasFalling();
			//If we are within time window and we arent perching / Targeting a perch (land on point/etc)
			if (bTimedAfterLanding && (PerchComp.GetState() == EPlayerPerchState::Inactive && !PerchComp.Data.bPerching))
			{
				if (WasActionStartedDuringTime(ActionNames::MovementDash, StepDashComp.Settings.InputBufferWindow))
					return true;
			}
		}
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FRollDashDeactivationParams& DeactivationParams) const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (DashMovementCalc.IsFinishedAtTime(ActiveDuration))
		{
			DeactivationParams.bFinished = true;
			return true;
		}

		if (MoveComp.HasUpwardsImpulse())
			return true;

		if (!MoveComp.IsOnWalkableGround())
		{
			DeactivationParams.bFell = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StepDashComp.bHasRolled = true;
		StepDashComp.CombinedDashCooldown = RollDashComp.Settings.DashCooldown + RollDashComp.Settings.DashDuration;

		StartPos = Player.ActorLocation;
		bRollDashBuffered = false;

		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementDash);

		Dir = MoveComp.MovementInput.GetSafeNormal();
		if (MoveComp.MovementInput.IsNearlyZero())
			Dir = Player.ActorForwardVector;

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

		if(StrafeComp.IsStrafeEnabled())
		{
			FVector CameraDir = Player.ViewRotation.ForwardVector.ConstrainToPlane(Player.MovementWorldUp);
			WantedPlayerRotation = CameraDir.ToOrientationQuat();
		}
		else
			WantedPlayerRotation = Dir.ToOrientationQuat();

		//Force Feedback
		if (RollDashComp.DashForceFeedback != nullptr)
			Player.PlayForceFeedback(RollDashComp.DashForceFeedback, false, false, this);

		float ExitSpeed = RollDashComp.Settings.ExitSpeed;
		if (SprintComp.IsSprintToggled())
			ExitSpeed = RollDashComp.Settings.ExitSpeedSprinting;

		DashMovementCalc = FDashMovementCalculator(
			GetCapabilityDeltaTime(),
			DashDistance = RollDashComp.Settings.DashDistance,
			DashDuration = RollDashComp.Settings.DashDuration,
			DashAccelerationDuration = RollDashComp.Settings.DashAccelerationDuration,
			DashDecelerationDuration = RollDashComp.Settings.DashDecelerationDuration,
			InitialSpeed = Player.GetActorHorizontalVelocity().Size(),
			WantedExitSpeed = ExitSpeed,
		);

		// Temporarily block certain capabilities like jump from interrupting the roll
		if (RollDashComp.Settings.BlockedRollStateDuration > 0.0)
		{
			EnterRollState();
		}

		RollDashComp.StartDash();
		Player.SetAnimTrigger(n"StartRollDash");

		//Assign Strafe values for RollDash
		RollDashComp.BS_Strafe_Direction.Y = Player.ActorForwardVector.DotProduct(Dir);
		RollDashComp.BS_Strafe_Direction.X = Player.ActorRightVector.DotProduct(Dir);

		UPlayerCoreMovementEffectHandler::Trigger_RollDash_Started(Player);

		Player.BlockCapabilities(BlockedWhileIn::Dash, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FRollDashDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(BlockedWhileIn::Dash, this);
		Player.ClearCameraSettingsByInstigator(this, 2.5);

		//If Deactivation params carried over sprint state and we are still giving input, then exit into sprint.
		if (DeactivationParams.bFinished)
		{
		}
		else if (DeactivationParams.bFell)
		{
			// If we fell down during the roll, and we have a buffered jump, trigger it
			if (bInRollState)
				ExitRollState();
		}
		else
		{
			// If we were interrupted by a block or something else unnatural, exit roll state
			// but ignore any buffered jumps because we're doing something else now
			if(bInRollState)
				ExitRollState();
		}

		// Don't allow inheriting the horizontal speed from a dash when we cancel it (Except if we transitioned into RollDashJump)
		if(!RollDashComp.bTriggeredRollDashJump)
			Player.SetActorHorizontalVelocity(
				Player.ActorHorizontalVelocity.GetClampedToMaxSize(DashMovementCalc.GetExitSpeed())
			);

		RollDashComp.StopDash();

		UPlayerCoreMovementEffectHandler::Trigger_RollDash_Stopped(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				//Define our direction based on input and allow it to snap within timeframe.
				if (ActiveDuration < RollDashComp.Settings.RedirectionWindow)
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

				// Movement.InterpRotationTo(WantedPlayerRotation, RollDashComp.Settings.RotationInterpSpeed);
				Movement.SetRotation(WantedPlayerRotation);

				if (MoveComp.IsOnWalkableGround())
					Movement.OverrideStepDownAmountForThisFrame(54.0);
				
				Movement.AddGravityAcceleration();
				Movement.AddOwnerVerticalVelocity();
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, StrafeComp.IsStrafeEnabled() ? n"StrafeDash" : n"Dash");

#if !RELEASE
			if (IsDebugActive())
			{
				PrintToScreenScaled("DashVel: " + MoveComp.HorizontalVelocity.Size(), Color = FLinearColor::Yellow);
			}
#endif

		}

		// If the player presses jump during the roll state, buffer it for later
		if (bInRollState && WasActionStarted(ActionNames::MovementJump))
			JumpComp.BufferJumpInput();
	}
};