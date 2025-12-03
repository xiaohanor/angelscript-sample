
class UPerchJumpToCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Perch);
	default CapabilityTags.Add(PlayerPerchPointTags::PerchPointJumpTo);

	default BlockExclusionTags.Add(PlayerMovementExclusionTags::ExcludePerch);
	

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 44;
	default TickGroupSubPlacement = 1;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USimpleMovementData Movement;
	UPlayerPerchComponent PerchComp;
	UPlayerJumpComponent JumpComp;
	UPlayerSprintComponent SprintComp;
	UPlayerAirMotionComponent AirMotionComp;
	UPlayerTargetablesComponent PlayerTargetablesComponent;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	float EnterTime;
	FVector LocalDirection;
	FVector LocalPosition;
	FVector LocalVelocity;

	FVector TargetLocation;

	float TargetedSplineDistance;

	// Air jump will be blocked during the last few frames of landing, so we don't get an airjump when we're expecting a jumpoff
	const float BlockAirJumpDuringLastDuration = 0.08;
	bool bAirJumpBlocked = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();
		PerchComp = UPlayerPerchComponent::GetOrCreate(Player);
		JumpComp = UPlayerJumpComponent::GetOrCreate(Player);
		SprintComp = UPlayerSprintComponent::GetOrCreate(Player);
		AirMotionComp = UPlayerAirMotionComponent::GetOrCreate(Player);
		PlayerTargetablesComponent = UPlayerTargetablesComponent::Get(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPerchPointJumpToActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!MoveComp.IsOnWalkableGround() && !JumpComp.IsInJumpGracePeriod() && !PerchComp.IsCurrentlyPerching())
			return false;

		bool bWantContextualMove = WasActionStartedDuringTime(ActionNames::ContextualMovement, 0.2);
		bool bWantJump = WasActionStartedDuringTime(ActionNames::MovementJump, 0.2) || JumpComp.IsJumpBuffered();
		
		if (!bWantJump && !bWantContextualMove)
			return false;

		if (bWantJump)
		{
			auto JumpTarget = Cast<UPerchPointComponent>(PlayerTargetablesComponent.GetPrimaryTargetForCategory(n"Jump"));
			if (JumpTarget != nullptr && JumpTarget.CanAutoJumpTo())
			{
				Params.SelectedPerchPoint = JumpTarget;
				return true;
			}
		}

		if (bWantContextualMove)
		{
			auto GrappleTarget = Cast<UPerchPointComponent>(PlayerTargetablesComponent.GetPrimaryTargetForCategory(n"ContextualMoves"));
			if (GrappleTarget != nullptr)
			{
				// Only do a jumpto grapple if we're close to the grapple point
				if (Player.ActorLocation.Distance(GrappleTarget.WorldLocation) <= GrappleTarget.ActivationRange)
				{
					Params.SelectedPerchPoint = GrappleTarget;
					Params.bReplacesGrapple = true;
					return true;
				}
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPerchPointJumpToDeactivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
		{
			Params.bMoveCompleted = false;
			return true;
		}

		if (MoveComp.HasCeilingContact() || MoveComp.HasWallContact())
		{
			Params.bMoveCompleted = false;
			return true;
		}

		if (PerchComp.Data.TargetedPerchPoint == nullptr || PerchComp.Data.TargetedPerchPoint.IsDisabledForPlayer(Player))
		{
			Params.bMoveCompleted = false;
			return true;
		}

		if (ActiveDuration >= EnterTime)
		{
			Params.bMoveCompleted = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPerchPointJumpToActivationParams Params)
	{
		if(!Params.SelectedPerchPoint.bBlockAirActionCancel)
			Player.BlockCapabilitiesExcluding(BlockedWhileIn::Perch, n"ExcludeAirJumpAndDash", this);
		else
			Player.BlockCapabilities(BlockedWhileIn::Perch, this);

		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementJump);
		Player.ConsumeButtonInputsRelatedTo(ActionNames::ContextualMovement);
		PerchComp.ResetJumpTimer();

		JumpComp.StopJumpGracePeriod();
		JumpComp.ConsumeBufferedJump();

		PerchComp.Data.TargetedPerchPoint = Params.SelectedPerchPoint;
		if (!Params.bReplacesGrapple)
			PerchComp.Data.TargetedPerchPoint.WorldTransform = Params.SelectedPerchPoint.GetJumpToTargetTransform(Player);
		PerchComp.CalculateDistAndAngleDiffs();

		//Broadcast events
		PerchComp.Data.TargetedPerchPoint.OnPlayerInitiatedJumpToEvent.Broadcast(Player, PerchComp.Data.TargetedPerchPoint);

		if (PerchComp.IsCurrentlyPerching())
		{
			PerchComp.Data.ActivePerchPoint.OnPlayerStoppedPerchingEvent.Broadcast(Player, PerchComp.Data.ActivePerchPoint);

			if(PerchComp.Data.ActiveSpline != nullptr)
				PerchComp.Data.ActiveSpline.OnPlayerJumpedOnSpline.Broadcast(Player);

			// If we are triggering a jumpto and we were _already_ perching, take over the camera settings from
			// the previous perch point until the jumpto is over, which will then trigger the camera settings from
			// the new perch point. This prevents the camera from going back and forth when jumping between multiple
			// perch points that have camera settings.
			if (PerchComp.Data.ActivePerchPoint.PerchCameraSetting != nullptr)
			{
				if (PerspectiveModeComp.IsCameraBehaviorEnabled())
					Player.ApplyCameraSettings(PerchComp.Data.ActivePerchPoint.PerchCameraSetting, 2.0, this, SubPriority = 44);
			}
		}

		PerchComp.StopPerching(false);	

		// Calculate a trajectory for hopping to the point
		FVector WorldUp = MoveComp.WorldUp;
		FVector DeltaToPerch = PerchComp.Data.TargetedPerchPoint.WorldLocation - Player.ActorLocation;
		FVector HorizontalDelta = DeltaToPerch.ConstrainToPlane(WorldUp);
		float HorizontalDistance = HorizontalDelta.Size();
		FVector DirectionToPerch = HorizontalDelta.GetSafeNormal();
		float HorizontalStartSpeed = DirectionToPerch.DotProduct(Player.ActorHorizontalVelocity);

		float WantedTime = 0.0;
		if (!DirectionToPerch.IsNearlyZero())
			WantedTime = HorizontalDistance / Math::Max(AirMotionComp.Settings.HorizontalMoveSpeed, HorizontalStartSpeed);

		// Make sure we don't take either really long or really short
		EnterTime = Math::Clamp(WantedTime, 0.4, 0.55);
		EnterTime -= 0.0325 * Math::Clamp(PerchComp.ChainedJumps, 0, 2);

		// Calculate how much we need to jump to be able to reach it with normal gravity
		float NeededVertical = Trajectory::GetSpeedToReachTarget(
			DeltaToPerch.DotProduct(WorldUp), EnterTime, -MoveComp.GetGravityForce(),
		);

		LocalPosition = Player.ActorLocation - PerchComp.Data.TargetedPerchPoint.WorldLocation;
		LocalDirection = DirectionToPerch;
		LocalVelocity = (WorldUp * NeededVertical) + DirectionToPerch * (HorizontalDistance / EnterTime);

		if(PerchComp.Data.TargetedPerchPoint.bHasConnectedSpline)
		{
			TargetedSplineDistance = PerchComp.Data.TargetedPerchPoint.ConnectedSpline.Spline.GetClosestSplineDistanceToWorldLocation(PerchComp.Data.TargetedPerchPoint.WorldLocation);
			TargetLocation = PerchComp.Data.TargetedPerchPoint.ConnectedSpline.Spline.GetWorldLocationAtSplineDistance(TargetedSplineDistance);
		}
		else
		{
			TargetLocation = PerchComp.Data.TargetedPerchPoint.WorldLocation;
		}

		Params.SelectedPerchPoint.IsPlayerJumpingToPoint[Player] = true;
		PerchComp.Data.EnterTime = EnterTime;
		PerchComp.Data.bPerching = false;
		PerchComp.SetState(EPlayerPerchState::JumpTo);
		PerchComp.AnimData.bInEnter = true;
		
		if (PerspectiveModeComp.IsCameraBehaviorEnabled())
			Player.ApplyCameraSettings(PerchComp.PerchPointEnterCamSetting, 0.45, this, SubPriority = 42);

		// If we're landing on a perch spline, the perch point itself won't be in the same location on both sides,
		// so we sync relative to the spline instead
		if (PerchComp.Data.TargetedPerchPoint.bHasConnectedSpline && PerchComp.Data.TargetedPerchPoint.ConnectedSpline != nullptr)
			MoveComp.ApplyCrumbSyncedRelativePosition(this, PerchComp.Data.TargetedPerchPoint.ConnectedSpline.Spline);
		else
			MoveComp.ApplyCrumbSyncedRelativePosition(this, PerchComp.Data.TargetedPerchPoint);

		UPlayerCoreMovementEffectHandler::Trigger_Perch_JumpTo(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPerchPointJumpToDeactivationParams Params)
	{
		Player.ClearCameraSettingsByInstigator(this);
		MoveComp.ClearCrumbSyncedRelativePosition(this);

		Player.UnblockCapabilities(BlockedWhileIn::Perch, this);
		if (bAirJumpBlocked)
		{
			Player.UnblockCapabilities(PlayerMovementTags::AirJump, this);
			bAirJumpBlocked = false;
		}

		if (Params.bMoveCompleted)
		{
			if(PerchComp.Data.TargetedPerchPoint.bAllowPerch)
			{
				bool bTeleportToPoint = !PerchComp.Data.TargetedPerchPoint.bIgnorePerchMovementDuringEnter;
				PerchComp.StartPerching(PerchComp.Data.TargetedPerchPoint, bTeleportToPoint);
			}
			else
			{
				FVector MoveInput = MoveComp.MovementInput;
				MoveComp.OverridePreviousGroundContactWithCurrent();
				Player.SetActorVelocity(MoveInput.GetSafeNormal() * 500.0);

				//TODO [AL]: Temp solution to StopPerching not being called when perching is cancelled by jump to (due to animation reasons).
				Player.ClearCameraSettingsByInstigator(PerchComp);

				PerchComp.SetState(EPlayerPerchState::Inactive);
			}
		}
		else
		{
			PerchComp.SetState(EPlayerPerchState::Inactive);
		}
		
		if (PerchComp.Data.TargetedPerchPoint != nullptr)
		{
			PerchComp.Data.TargetedPerchPoint.IsPlayerJumpingToPoint[Player] = false;

			//Clear our targeted here as either its become our active perch point or we deactivated due to reasons which should cause a retarget
			PerchComp.Data.TargetedPerchPoint = nullptr;
		}

		PerchComp.AnimData.bInEnter = false;
		Player.ClearCameraSettingsByInstigator(this, 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				if (!PerchComp.Data.TargetedPerchPoint.bIgnorePerchMovementDuringEnter)
				{
					//If we are targeting a spline make sure that the point moving to align with player doesnt change our target position (due to current PerchSpline setup)
					if(PerchComp.Data.TargetedPerchPoint.bHasConnectedSpline)
						TargetLocation = PerchComp.Data.TargetedPerchPoint.ConnectedSpline.Spline.GetWorldLocationAtSplineDistance(TargetedSplineDistance);
					else
						TargetLocation = PerchComp.Data.TargetedPerchPoint.WorldLocation;
				}

				FVector Gravity = MoveComp.GetGravity();
				LocalPosition += LocalVelocity * DeltaTime;

				LocalVelocity += Gravity * DeltaTime;
				LocalPosition += Gravity * DeltaTime * DeltaTime * 0.5;

				FVector NewLoc = TargetLocation + LocalPosition;
				FVector DeltaMove = NewLoc - Player.ActorLocation;

				FQuat TargetRot = FQuat::MakeFromZX(MoveComp.WorldUp, LocalDirection);
				FQuat Rot = Math::QInterpTo(Player.ActorRotation.Quaternion(), TargetRot, DeltaTime, 13.0);

				// JumpTos should never cause crazy velocity, even if they are fast as hell
				// We can interrupt this with an air jump and we don't want that to go crazy
				FVector CustomVelocity = (DeltaMove / DeltaTime).GetClampedToMaxSize(
					SprintComp.Settings.MaximumSpeed * MoveComp.MovementSpeedMultiplier
				);

				Movement.SetRotation(Rot);
				Movement.AddDeltaWithCustomVelocity(DeltaMove, CustomVelocity);
				Movement.IgnoreSplineLockConstraint();
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			// MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Perch");
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Perch");
		}

		// Block air jump once we get close enough
		if (!bAirJumpBlocked && ActiveDuration >= EnterTime - BlockAirJumpDuringLastDuration)
		{
			Player.BlockCapabilities(PlayerMovementTags::AirJump, this);
			bAirJumpBlocked = true;
		}
	}
}

struct FPerchPointJumpToActivationParams
{
	UPerchPointComponent SelectedPerchPoint;
	bool bReplacesGrapple = false;
}

struct FPerchPointJumpToDeactivationParams
{
	bool bMoveCompleted = false;
}