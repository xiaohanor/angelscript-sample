struct FGrappleToPerchExitActivationParams
{
	FPlayerGrappleData Data;
}

struct FGrappleToPerchExitDeactivationParams
{
	bool bMoveCompleted = false;
}

class UPlayerGrappleToPerchExitCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Grapple);
	default CapabilityTags.Add(PlayerGrappleTags::GrappleMovement);

	default BlockExclusionTags.Add(PlayerMovementExclusionTags::ExcludeGrapple);

	default DebugCategory = n"Movement";
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 4;
	default TickGroupSubPlacement = 4;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UPlayerGrappleComponent GrappleComp;
	UPlayerFloorMotionComponent FloorMotionComp;
	UPlayerAirMotionComponent AirMotionComp;
	UPlayerPerchComponent PerchComp;
	UPlayerSprintComponent SprintComp;

	UPerchPointComponent TargetedPerchPoint;

	float EnterTime;
	float TargetedSplineDistance;
	FVector LocalDirection;
	FVector LocalPosition;
	FVector LocalVelocity;
	FVector TargetLocation;

	const float HORIZONTAL_REDIRECTION_THRESHOLD = 45;

	//
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		GrappleComp = UPlayerGrappleComponent::Get(Player);
		FloorMotionComp = UPlayerFloorMotionComponent::Get(Player);
		AirMotionComp = UPlayerAirMotionComponent::Get(Player);
		PerchComp = UPlayerPerchComponent::Get(Player);
		SprintComp = UPlayerSprintComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (GrappleComp.Data.CurrentGrapplePoint == nullptr)
			return false;

		auto PerchPoint = Cast<UPerchPointComponent>(GrappleComp.Data.CurrentGrapplePoint);
		if (PerchPoint == nullptr || GrappleComp.Data.GrappleState != EPlayerGrappleStates::GrapplePerch)
			return false;

		if (!GrappleComp.Data.bPerformPerchExit)
			return false;

		if (!GrappleComp.Data.bGrappleToPointFinished)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGrappleToPerchExitDeactivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (TargetedPerchPoint.IsDisabledForPlayer(Player))
		{
			return true;
		}

		if (ActiveDuration >= EnterTime)
		{
			Params.bMoveCompleted = true;
			return true;
		}

		if (!MoveComp.PreviousHorizontalVelocity.IsNearlyZero() && MoveComp.HorizontalVelocity.IsNearlyZero())
			return true;

		if(ShouldDeactivateDueHorizontalRedirect())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TargetedPerchPoint = Cast<UPerchPointComponent>(GrappleComp.Data.CurrentGrapplePoint);
		Player.BlockCapabilities(BlockedWhileIn::Grapple, this);

		GrappleComp.Data.GrappleState = EPlayerGrappleStates::GrapplePerchExit;

		//Calculate our trajectory as well as our EnterTime
		FVector WorldUp = MoveComp.WorldUp;
		FVector DeltaToPerch = TargetedPerchPoint.WorldLocation - Player.ActorLocation;
		FVector HorizontalDelta = DeltaToPerch.ConstrainToPlane(WorldUp);
		float HorizontalDistance = HorizontalDelta.Size();
		FVector DirectionToPerch = HorizontalDelta.GetSafeNormal();
		float HorizontalStartSpeed = DirectionToPerch.DotProduct(Player.ActorHorizontalVelocity);

		float WantedTime = 0.0;
		if(!DirectionToPerch.IsNearlyZero())
			WantedTime = HorizontalDelta.Size() / Math::Max(AirMotionComp.Settings.HorizontalMoveSpeed, HorizontalStartSpeed);

		//Clamp our entry time within a reasonable range
		EnterTime = Math::Clamp(WantedTime, 0.5, 0.7);
		float NeededVertical = Trajectory::GetSpeedToReachTarget(DeltaToPerch.DotProduct(WorldUp), EnterTime, -MoveComp.GetGravityForce());

		LocalPosition = Player.ActorLocation - TargetedPerchPoint.WorldLocation;
		LocalDirection = DirectionToPerch;
		LocalVelocity = (WorldUp * NeededVertical) + DirectionToPerch * (HorizontalDistance / EnterTime);

		if (TargetedPerchPoint.bHasConnectedSpline)
		{
			TargetedSplineDistance = TargetedPerchPoint.ConnectedSpline.Spline.GetClosestSplineDistanceToWorldLocation(TargetedPerchPoint.WorldLocation);
			TargetLocation = TargetedPerchPoint.ConnectedSpline.Spline.GetWorldLocationAtSplineDistance(TargetedSplineDistance);
		}
		else
		{
			TargetLocation = TargetedPerchPoint.WorldLocation;
		}

		//Broadcast eventual events

		//Feedback/Etc

		// FHazeCameraImpulse Impulse;
		// Impulse.WorldSpaceImpulse = MoveComp.WorldUp * 2500;
		// Impulse.Dampening = 0.8;
		// Impulse.ExpirationForce = 250;
		// Player.ApplyCameraImpulse(Impulse, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGrappleToPerchExitDeactivationParams Params)
	{
		Player.UnblockCapabilities(BlockedWhileIn::Grapple, this);

		if (Params.bMoveCompleted)
		{
			if(TargetedPerchPoint.bAllowPerch)
			{
				if(TargetedPerchPoint.bHasConnectedSpline)
				{
					float Fraction = (TargetedSplineDistance / TargetedPerchPoint.ConnectedSpline.Spline.SplineLength);
					PerchComp.StartPerchingOnSplineFraction(TargetedPerchPoint, Fraction);
				}
				else
				{
					PerchComp.StartPerching(TargetedPerchPoint);
				}
			}
			else
			{	
				FVector MoveInput = MoveComp.MovementInput;
				MoveComp.OverridePreviousGroundContactWithCurrent();
				Player.SetActorVelocity(MoveInput.GetSafeNormal() * 500.0);

				PerchComp.SetState(EPlayerPerchState::Inactive);
			}

			if (IsValid(TargetedPerchPoint))
				TargetedPerchPoint.OnPlayerFinishedGrapplingToPointEvent.Broadcast(Player, TargetedPerchPoint);
		}
		else
		{
			//Move was interrupted
			if (IsValid(TargetedPerchPoint))
				TargetedPerchPoint.OnPlayerInterruptedGrapplingToPointEvent.Broadcast(Player, TargetedPerchPoint);
		}

		GrappleComp.Data.ResetData();
		GrappleComp.AnimData.ResetData();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				if(!TargetedPerchPoint.bIgnorePerchMovementDuringEnter)
				{
					//If we are targeting a spline make sure that the point moving to align with player doesnt change our target position (due to current PerchSpline setup)
					if(PerchComp.Data.TargetedPerchPoint.bHasConnectedSpline)
						TargetLocation = TargetedPerchPoint.ConnectedSpline.Spline.GetWorldLocationAtSplineDistance(TargetedSplineDistance);
					else
						TargetLocation = TargetedPerchPoint.WorldLocation;
				}

				FVector Gravity = MoveComp.GetGravity();
				LocalPosition += LocalVelocity * DeltaTime;

				LocalVelocity += Gravity * DeltaTime;
				LocalPosition += Gravity * DeltaTime * DeltaTime * 0.5;

				FVector NewLoc = TargetLocation + LocalPosition;
				FVector DeltaMove = NewLoc - Player.ActorLocation;

				//Clamp our final move if we overshoot our target location
				if(DeltaMove.Size() > (TargetLocation - Player.ActorLocation).Size())
					DeltaMove = DeltaMove.GetSafeNormal() * (TargetLocation - Player.ActorLocation).Size();

				FQuat TargetRot = FQuat::MakeFromZX(MoveComp.WorldUp, LocalDirection);
				FQuat Rot = Math::QInterpTo(Player.ActorRotation.Quaternion(), TargetRot, DeltaTime, 13.0);

				//Control our customVelocity incase we cancel this move into something else
				FVector CustomVelocity = (DeltaMove / DeltaTime).GetClampedToMaxSize(
					SprintComp.Settings.MaximumSpeed * MoveComp.MovementSpeedMultiplier
				);

				Movement.SetRotation(Rot);
				Movement.AddDeltaWithCustomVelocity(DeltaMove, CustomVelocity);
				Movement.IgnoreSplineLockConstraint();

			}
			else
			{
				// Follow the crumb trail on the remote side
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Grapple");
		}
	}

	//Check if we redirected our horizontal velocity to far from our to point direction
	bool ShouldDeactivateDueHorizontalRedirect() const
	{
		float AngularDistance = MoveComp.HorizontalVelocity.GetSafeNormal().AngularDistanceForNormals((TargetLocation - Player.ActorLocation).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal());
		if(AngularDistance > HORIZONTAL_REDIRECTION_THRESHOLD)
			return true;
	
		return false;
	}
};

