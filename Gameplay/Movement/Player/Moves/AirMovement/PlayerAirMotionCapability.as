
class UPlayerAirMotionCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::AirMotion);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 160;

	UPlayerMovementComponent MoveComp;
	UPlayerAirMotionComponent AirMotionComp;
	UPlayerFloorMotionComponent JogComp;
	UPlayerSprintComponent SprintComp;
	UPlayerLandingComponent LandingComp;
	UPlayerFloorMotionComponent FloorMotionComp;
	USteppingMovementData Movement;

	bool bUseGroundedTraceDistance = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		AirMotionComp = UPlayerAirMotionComponent::GetOrCreate(Player);
		JogComp = UPlayerFloorMotionComponent::GetOrCreate(Player);
		SprintComp = UPlayerSprintComponent::GetOrCreate(Player);
		LandingComp = UPlayerLandingComponent::GetOrCreate(Player);
		FloorMotionComp = UPlayerFloorMotionComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		//Incase we got a launch player call then hold the animdata for a couple of frames before clearing
		if(AirMotionComp.AnimData.bPlayerLaunchDetected && Time::FrameNumber - 1 > AirMotionComp.AnimData.LaunchDetectedFrameCount)
		{
			AirMotionComp.AnimData.ResetLaunchData();
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::AirMotion, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::AirMotion, this);
		bUseGroundedTraceDistance = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			CalculateAnimData();

			if(HasControl())
			{
				FVector AirControlVelocity = AirMotionComp.CalculateStandardAirControlVelocity(
					MoveComp.MovementInput,
					MoveComp.HorizontalVelocity,
					DeltaTime,
				);
				Movement.AddHorizontalVelocity(AirControlVelocity);

				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
				Movement.AddPendingImpulses();
				Movement.ApplyUnstableEdgeDistance(FMovementSettingsValue::MakePercentage(0.45));

				/*
					Calculate how fast the player should rotate when falling at fast speeds
				*/

				const float CurrentFallingSpeed = Math::Max((-MoveComp.WorldUp).DotProduct(MoveComp.VerticalVelocity), 0.0);
				const float RotationSpeedAlpha = Math::Clamp((CurrentFallingSpeed - AirMotionComp.Settings.MaximumTurnRateFallingSpeed) / AirMotionComp.Settings.MinimumTurnRateFallingSpeed, 0.0, 1.0);

				float FacingDirectionInterpSpeed = Math::Lerp(AirMotionComp.Settings.MaximumTurnRate, AirMotionComp.Settings.MinimumTurnRate, RotationSpeedAlpha);
				FacingDirectionInterpSpeed = FacingDirectionInterpSpeed * AirMotionComp.GetAirControlWeakeningMultiplier(true);

				//Incase our weakening multiplier is 0 then dont rotate at all (attempting to rotate with a speed of 0 will snap)
				if(FacingDirectionInterpSpeed != 0)
					Movement.InterpRotationToTargetFacingRotation(FacingDirectionInterpSpeed * (MoveComp.MovementInput.Size()));
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			// If this is the reset frame, we use a bigger stepdown
			// to find out if we are grounded or not
			if(!MoveComp.bHasPerformedAnyMovementSinceReset || bUseGroundedTraceDistance)
			{
				Movement.ForceGroundedStepDownSize();
			}

			bool bIsGrounded = MoveComp.IsOnAnyGround();
			if(!HasControl() && !bIsGrounded)
			{
				// On remote, we may still want to ground trace
				FMovementHitResult RemoteGroundHit;
				MoveComp.GroundTrace(RemoteGroundHit, 10);
				bIsGrounded = RemoteGroundHit.IsAnyGroundContact();
			}

			if ((!bIsGrounded && ActiveDuration > 0) || MoveComp.WasFalling())
				Movement.RequestFallingForThisFrame();
			MoveComp.ApplyMove(Movement);

			if(AirMotionComp.AnimData.bPlayerLaunchDetected)
			{
				if (Player.Mesh.CanRequestLocomotion())
					Player.Mesh.RequestLocomotion(n"Launch", this);
				AirMotionComp.AnimData.ResetLaunchData();
			}
			else if(bIsGrounded)
			{
				// We need to request grounded if this capability finds
				// the ground, else we will get a small step animation
				// in the beginning after a reset
				if (Player.Mesh.CanRequestLocomotion())
					Player.Mesh.RequestLocomotion(n"Movement", this);
				bUseGroundedTraceDistance = true;
			}
			else
			{
				if (Player.Mesh.CanRequestLocomotion())
					Player.Mesh.RequestLocomotion(n"AirMovement", this);
			}
		}
	}

	void CalculateAnimData()
	{
		AirMotionComp.AnimData.ForwardAlignedVelocityAlpha = Math::GetMappedRangeValueClamped(FVector2D(AirMotionComp.Settings.ANIM_LAUNCH_MAX_HORIZONTAL_VEL, -AirMotionComp.Settings.ANIM_LAUNCH_MAX_HORIZONTAL_VEL), FVector2D(1, -1), MoveComp.HorizontalVelocity.DotProduct(Player.ActorForwardVector));
		AirMotionComp.AnimData.RightAlignedVelocityAlpha = Math::GetMappedRangeValueClamped(FVector2D(AirMotionComp.Settings.ANIM_LAUNCH_MAX_HORIZONTAL_VEL, -AirMotionComp.Settings.ANIM_LAUNCH_MAX_HORIZONTAL_VEL), FVector2D(1, -1), MoveComp.HorizontalVelocity.DotProduct(Player.ActorRightVector));
	}
}