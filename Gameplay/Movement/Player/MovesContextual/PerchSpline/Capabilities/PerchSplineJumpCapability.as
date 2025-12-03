class UPerchSplineJumpCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Perch);
	default CapabilityTags.Add(PlayerMovementTags::Jump);

	default BlockExclusionTags.Add(PlayerMovementExclusionTags::ExcludePerch);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 50;
	default TickGroupSubPlacement = 3;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerPerchComponent PerchComp;
	UPlayerJumpComponent JumpComp;
	UPlayerAirMotionComponent AirMotionComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	bool bImpulseAdded = false;
	bool bForceJump = false;
	float ImpulseDelay = 0.06;
	float HorizontalMoveSpeed;

	float VerticalDistanceToSpline;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		PerchComp = UPlayerPerchComponent::GetOrCreate(Player);
		JumpComp = UPlayerJumpComponent::GetOrCreate(Player);
		AirMotionComp = UPlayerAirMotionComponent::GetOrCreate(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (PerchComp.Data.State != EPlayerPerchState::PerchingOnSpline)
			return false;

		if (!PerchComp.bIsGroundedOnPerchSpline)
			return false;

		// if(!MoveComp.HasCustomMovementStatus(n"Perching"))
		// 	return false;

		if (!WasActionStartedDuringTime(ActionNames::MovementJump, 0.3))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (MoveComp.HasGroundContact())
			return true;

		if (MoveComp.HasCeilingContact())
			return true;

		if (MoveComp.HasImpulse())
			return true;

		if (MoveComp.VerticalVelocity.DotProduct(MoveComp.WorldUp) <= 0.0)
		{
			if (PerchComp.Data.State != EPlayerPerchState::PerchingOnSpline)
				return true;
			if (VerticalDistanceToSpline < 5.0)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementJump);
		JumpComp.ConsumeBufferedJump();

		PerchComp.Data.bSplineJump = true;

		// If this jump allowed us to leave the spline, immediately nuke the spline lock
		// We can't wait for PerchSplineCapability to do this, because that will be a frame late,
		// which causes us to lose our jump horizontal velocity!
		if (PerchComp.VerifyReachedPerchSplineEnd(true) /*|| PerchComp.Data.ActiveSpline.bSoftPerchLock*/)
			Player.UnlockPlayerMovementFromSpline(n"PerchSpline");

		FVector MoveInput = MoveComp.MovementInput;

		FVector VerticalVelocity = MoveComp.WorldUp * JumpComp.Settings.PerchImpulse;
		Player.SetActorVerticalVelocity(VerticalVelocity);
		Player.SetActorHorizontalVelocity(MoveInput * JumpComp.Settings.PerchImpulse * JumpComp.Settings.HorizontalPerchImpulseMultiplier);

		if (PerspectiveModeComp.IsCameraBehaviorEnabled())
		{
			Player.ApplyCameraSettings(PerchComp.PerchPointJumpOffCamSetting, 2.5, this, SubPriority = 42);
			Player.PlayCameraShake(PerchComp.PerchJumpOffCamShake, this, 1.0);

			FHazeCameraImpulse CamImpulse;
			CamImpulse.AngularImpulse = FRotator(20.0, 0.0, 0.0);
			CamImpulse.CameraSpaceImpulse = FVector(0.0, 0.0, 425.0);
			CamImpulse.ExpirationForce = 15.5;
			CamImpulse.Dampening = 0.8;
			Player.ApplyCameraImpulse(CamImpulse, this);
		}

		VerticalDistanceToSpline = MAX_flt;

		if(IsValid(PerchComp.Data.ActiveSpline))
			PerchComp.Data.ActiveSpline.OnPlayerJumpedOnSpline.Broadcast(Player);

		UPlayerCoreMovementEffectHandler::Trigger_Perch_Spline_Jump(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PerchComp.Data.bSplineJump = false;
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector AirControlVelocity = AirMotionComp.CalculateStandardAirControlVelocity(
					MoveComp.MovementInput,
					MoveComp.HorizontalVelocity,
					DeltaTime,
				);
				Movement.AddHorizontalVelocity(AirControlVelocity);

				if (PerchComp.Data.bInPerchSpline)
				{
					float SplineDistance = PerchComp.Data.ActiveSpline.Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation); 
					FVector SplineLocation = PerchComp.Data.ActiveSpline.Spline.GetWorldLocationAtSplineDistance(SplineDistance);

					// Fall, but don't allow falling below the spline
					float VerticalVelocity = MoveComp.VerticalVelocity.DotProduct(MoveComp.WorldUp);
					float VerticalDelta = VerticalVelocity * DeltaTime;
					VerticalDelta -= MoveComp.GetGravityForce() * DeltaTime * DeltaTime * 0.5;
					VerticalVelocity -= MoveComp.GetGravityForce() * DeltaTime;

					VerticalDistanceToSpline = Math::Max((Player.ActorLocation - SplineLocation).DotProduct(MoveComp.WorldUp), 0.0);
					if (VerticalDelta < -VerticalDistanceToSpline)
					{
						VerticalDelta = -VerticalDistanceToSpline;
						VerticalVelocity = 0.0;
						VerticalDistanceToSpline = 0.0;
					}

					Movement.AddDeltaWithCustomVelocity(MoveComp.WorldUp * VerticalDelta, MoveComp.WorldUp * VerticalVelocity);
				}
				else
				{
					// We've left the spline, so use normal gravity
					Movement.AddOwnerVerticalVelocity();
					Movement.AddGravityAcceleration();
				}

				Movement.InterpRotationToTargetFacingRotation((PerchComp.Settings.PerchSplineJumpFacingInterpSpeed) * MoveComp.MovementInput.Size());
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			Movement.RequestFallingForThisFrame();
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Perch");

			if (IsValid(PerchComp.Data.ActiveSpline))
				PerchComp.Data.CurrentSplineDistance = PerchComp.Data.ActiveSpline.Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
		}
	}
}