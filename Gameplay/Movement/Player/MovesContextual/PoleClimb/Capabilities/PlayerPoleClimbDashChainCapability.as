
class UPlayerPoleClimbDashChain : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::PoleClimb);
	default CapabilityTags.Add(PlayerPoleClimbTags::PoleClimbDash);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 23;
	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 22);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USimpleMovementData Movement;
	UPlayerPoleClimbComponent PoleClimbComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	float TargetHeight;
	float CurrentHeight;
	float StartHeight;

	FDashMovementCalculator DashMoveCalc;

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();
		PoleClimbComp = UPlayerPoleClimbComponent::GetOrCreate(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPoleClimbJumpUpActivationParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!PoleClimbComp.IsClimbing() && (PoleClimbComp.GetState() != EPlayerPoleClimbState::Dash || PoleClimbComp.GetState() != EPlayerPoleClimbState::ChainDash))
			return false;

		if(PoleClimbComp.State == EPlayerPoleClimbState::Dash && !PoleClimbComp.IsWithinDashChainWindow())
			return false;

		if (PoleClimbComp.GetState() == EPlayerPoleClimbState::Enter)
			return false;

		if(PoleClimbComp.Data.bPerformingTurnaround)
			return false;

		if(PoleClimb::bUseAlternateClimbControls)
			return false;

		if(!VerifyInputDirection())
			return false;

		if(!WasActionStartedDuringTime(ActionNames::MovementDash, PoleClimbComp.Settings.DashInputBufferWindow))
			return false;

		if(PoleClimbComp.Data.ActivePole.PoleType == EPoleType::Slippery && !PoleClimbComp.Data.ActivePole.bAllowClimbingUp)
			return false;
		
		FPoleClimbJumpUpActivationParams TestParams;
		if(!VerifyMinimumJumpUpHeight(TestParams))
			return false;

		Params = TestParams;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPoleClimbJumpUpDeactivationParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(PoleClimbComp.Data.ActivePole == nullptr)
		{
			Params.DeactivationType = EPlayerPoleClimbJumpUpDeactivationTypes::Interrupted;
			return true;
		}

		if (!PoleClimbComp.IsWithinValidClimbHeight())
		{
			Params.DeactivationType = EPlayerPoleClimbJumpUpDeactivationTypes::Interrupted;
			return true;
		}

		if(!PoleClimbComp.IsClimbing() && (PoleClimbComp.GetState() != EPlayerPoleClimbState::Dash || PoleClimbComp.GetState() != EPlayerPoleClimbState::ChainDash))
		{
			Params.DeactivationType = EPlayerPoleClimbJumpUpDeactivationTypes::Interrupted;
			return true;
		}
		
		if(PoleClimbComp.Data.ActivePole.IsActorDisabled() || PoleClimbComp.Data.ActivePole.IsPoleDisabled())
		{
			Params.DeactivationType = EPlayerPoleClimbJumpUpDeactivationTypes::Interrupted;
			return true;
		}

		if (MoveComp.HasCeilingContact())
		{
			Params.DeactivationType = EPlayerPoleClimbJumpUpDeactivationTypes::MoveCompleted;
			return true;
		}
		
		// Check if the dash is over
		if(DashMoveCalc.IsFinishedAtTime(ActiveDuration))
		{
			Params.DeactivationType = EPlayerPoleClimbJumpUpDeactivationTypes::MoveCompleted;
			return true;
		}

		// If the dash is currently _decelerating_, but we are holding the input to go up,
		// and we've already decelerated sufficiently to our normal speed, the dash should finish.
		// This way we don't go down to 0 velocity unnecessarily and things will be smoother
		if (DashMoveCalc.IsDeceleratingAtTime(ActiveDuration))
		{
			FVector2D MoveInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
			if (MoveInput.Y > 0.0)
			{
				float InputAlpha = Math::GetMappedRangeValueClamped(FVector2D(PoleClimbComp.Settings.VerticalDeadZone, 1.0),FVector2D(0.0, 1.0), MoveInput.Y);
				float TargetVerticalSpeed = PoleClimbComp.Settings.ClimbSpeed * InputAlpha;
				float CurrentSpeed = DashMoveCalc.GetSpeedAtTime(ActiveDuration);
				if (CurrentSpeed <= TargetVerticalSpeed)
				{
					Params.DeactivationType = EPlayerPoleClimbJumpUpDeactivationTypes::MoveCompleted;
					return true;
				}
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPoleClimbJumpUpActivationParams Params)
	{
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementDash);
		Player.BlockCapabilities(BlockedWhileIn::PoleClimb, this);

		if(PoleClimbComp.State == EPlayerPoleClimbState::Dash)
		{
			PoleClimbComp.SetState(EPlayerPoleClimbState::ChainDash);
		}
		else if(PoleClimbComp.State == EPlayerPoleClimbState::ChainDash)
		{
			PoleClimbComp.SetState(EPlayerPoleClimbState::Dash);
		}
		else
		{
			PoleClimbComp.SetState(EPlayerPoleClimbState::Dash);
		}

		PoleClimbComp.AnimData.bJumpingUp = true;

		MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this);

#if !RELEASE
		if(IsDebugActive())
			PrintToScreen("VerticalVel: " + MoveComp.VerticalVelocity.DotProduct(MoveComp.WorldUp), 5.0);
#endif	
		
		StartHeight = PoleClimbComp.Data.CurrentHeight;
		TargetHeight = StartHeight + (Params.HeightDelta * PoleClimbComp.Data.ClimbDirectionSign);
		CurrentHeight = StartHeight;

		//Initiate our dash calculation
		DashMoveCalc = FDashMovementCalculator(
			GetCapabilityDeltaTime(),
		DashDistance = Params.HeightDelta,
		DashDuration = PoleClimbComp.Settings.DashDuration,
		DashAccelerationDuration = PoleClimbComp.Settings.DashAccelerationDuration,
		DashDecelerationDuration = PoleClimbComp.Settings.DashDecelerationDuration,
		InitialSpeed = MoveComp.GetVerticalSpeed(),
		WantedExitSpeed = 0
		);

		if (PerspectiveModeComp.IsCameraBehaviorEnabled())
			Player.ApplyCameraSettings(PoleClimbComp.PoleClimbDashSettings, 0, this, SubPriority = 54);

		Player.PlayForceFeedback(PoleClimbComp.DashFF, false, true, this, 1.0);

		UPlayerCoreMovementEffectHandler::Trigger_Pole_DashStarted(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPoleClimbJumpUpDeactivationParams Params)
	{
		Player.UnblockCapabilities(BlockedWhileIn::PoleClimb, this);
		Player.ClearCameraSettingsByInstigator(this);

		MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);

		if(Params.DeactivationType == EPlayerPoleClimbJumpUpDeactivationTypes::MoveCompleted)
		{
			if(PoleClimbComp.State == EPlayerPoleClimbState::Dash || PoleClimbComp.GetState() == EPlayerPoleClimbState::ChainDash)
				PoleClimbComp.Data.State = EPlayerPoleClimbState::Climbing;
		}
		else if(Params.DeactivationType == EPlayerPoleClimbJumpUpDeactivationTypes::Interrupted)
		{
			PoleClimbComp.SetState(EPlayerPoleClimbState::Inactive);
			PoleClimbComp.StopClimbing();
		}
		else
		{
			if(IsBlocked())
			{
				//we deactivated due to being blocked
				if(IsBlockedByTag(PlayerPoleClimbTags::PoleClimbDash))
				{
					//Only dash was blocked so return to climb
					PoleClimbComp.SetState(EPlayerPoleClimbState::Climbing);
				}
				else
				{
					//We were probably blocked on a bigger scale (Poleclimb as a whole or movement), so default out of poleclimb
					PoleClimbComp.SetState(EPlayerPoleClimbState::Inactive);
					PoleClimbComp.StopClimbing();
				}
			}
			else
			{
				if(PoleClimbComp.GetState() == EPlayerPoleClimbState::Dash || PoleClimbComp.GetState() == EPlayerPoleClimbState::ChainDash)
				{
					//We werent blocked, move didnt complete but the alternate dash capability took over during the chain dash window most likely
				}
				else
				{
					//Something interrupted the move
					PoleClimbComp.SetState(EPlayerPoleClimbState::Inactive);
					PoleClimbComp.StopClimbing();
				}
			}
		}

		StartHeight = 0;
		TargetHeight = 0;
		CurrentHeight = 0;

		UPlayerCoreMovementEffectHandler::Trigger_Pole_DashStopped(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				float FrameMove;
				float FrameSpeed;
				DashMoveCalc.CalculateMovement(ActiveDuration, DeltaTime, FrameMove, FrameSpeed);

				FVector Direction = PoleClimbComp.Data.ActivePole.ActorUpVector.GetSafeNormal() * PoleClimbComp.Data.ClimbDirectionSign;
				FVector TargetLocation = PoleClimbComp.Data.ActivePole.ActorLocation;
				TargetLocation += PoleClimbComp.GetPoleToPlayerVector() * PoleClimbComp.Settings.PlayerPoleHorizontalOffset;
				TargetLocation += PoleClimbComp.Data.ActivePole.ActorUpVector * CurrentHeight;
				TargetLocation += Direction * FrameMove;

				FVector DeltaMove = TargetLocation - Player.ActorLocation;

				//it might be possible here to go above the max height of the pole (given we dont have collision above) which causes an instant cancel
				//we might need to readjust our location here if we go above max or clamp the final move OR we add a slight margin of error to our auto cancel from poleclimb
				CurrentHeight += PoleClimbComp.Data.ClimbDirectionSign * FrameMove;
				PoleClimbComp.Data.CurrentHeight = CurrentHeight;

				PoleClimbComp.SetPoleDashProgress(ActiveDuration);

				Movement.AddDeltaWithCustomVelocity(DeltaMove, Direction * FrameSpeed);
				Movement.SetRotation(Player.ActorRotation);
				Movement.IgnoreSplineLockConstraint();
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"PoleClimb");
		}
	}

	bool VerifyMinimumJumpUpHeight(FPoleClimbJumpUpActivationParams& Params) const
	{
		if(PoleClimbComp.Data.ActivePole == nullptr)
			return false;

		float TotalRemainingHeight = PoleClimbComp.Data.ClimbDirectionSign == 1 ? PoleClimbComp.Data.MaxHeight - PoleClimbComp.Data.CurrentHeight : Math::Abs(PoleClimbComp.Data.MinHeight - PoleClimbComp.Data.CurrentHeight);

		if(TotalRemainingHeight < PoleClimbComp.Settings.DashDistanceMin)
			return false;
		
		Params.HeightDelta = Math::Min(TotalRemainingHeight, PoleClimbComp.Settings.DashDistanceMax);
		return true;
	}

	bool VerifyInputDirection() const
	{
		FVector2D RawInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
		FVector CameraUp = Player.ViewRotation.UpVector;
		FVector CameraRight = Player.ViewRotation.RightVector;
		FVector ViewAlignedInput = CameraUp * RawInput.Y + CameraRight * RawInput.X;

		if(ViewAlignedInput.DotProduct(MoveComp.WorldUp) >= 0)
			return true;

		return false;
	}
}