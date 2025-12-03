class USkylineInnerCityHitSwingGroundMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::Movement);
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 90;

	ASkylineInnerCityHitSwing SwingThing;

	UHazeMovementComponent MoveComp;
	USkylineInnerCityHitSwingMovementData Movement;
	float BounceEventCooldown = 0.0;

	FHazeAcceleratedFloat AccCleaningSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwingThing = Cast<ASkylineInnerCityHitSwing>(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		Movement = MoveComp.SetupMovementData(USkylineInnerCityHitSwingMovementData);
		DevTogglesSkyline::Skyline.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!MoveComp.IsOnWalkableGround())
			return false;

		if(ShouldAutoDetach())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!MoveComp.IsOnWalkableGround())
			return true;

		if(ShouldAutoDetach())
			return true;

		return false;
	}

	bool ShouldAutoDetach() const
	{
		if (!DevTogglesSkyline::WindShieldRobotAutoDetach.IsEnabled())
			return false;

		bool bAutoDeactivate = IsActive() && ActiveDuration > 5.0;
		bool bShouldBeInactive = !IsActive() && DeactiveDuration < 1.0;
		if (bAutoDeactivate || bShouldBeInactive)
			return true;
		else
			return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement, SwingThing.ActorUpVector))
			return;

		if (HasControl())
		{
			Movement.SetIsClampedToPlane(true);
			Movement.SetMoveClampPlaneNormal(SwingThing.ActorUpVector);

			// We only do the movement on the horizontal velocity
			FVector HorizontalVelocity = MoveComp.HorizontalVelocity;
			Movement.AddVelocity(HorizontalVelocity);

			// Apply drag
			FVector Acceleration = -HorizontalVelocity * InnerCityHitSwing::Drag;
			Movement.AddAcceleration(Acceleration);
			
			// Make sure we fall towards the floor
			Movement.AddOwnerVerticalVelocity();
			Movement.AddGravityAcceleration();

			// Add any impulses that were added from being hit
			Movement.AddPendingImpulses();

			// add some ambient movement
			if (SwingThing.bAllowIdleMovement)
			{
				ASplineActor MoveSpline;
				float Dist;

				if (!SwingThing.HasBeenHit())
				{
					MoveSpline = SwingThing.StartMoveSpline;
					Dist = MoveSpline.Spline.GetClosestSplineDistanceToWorldLocation(SwingThing.ActorLocation);
				}
				else
				{
					FVector Spline1Loc = SwingThing.IdleMoveSpline1.Spline.GetClosestSplineWorldLocationToWorldLocation(SwingThing.ActorLocation);
					FVector Spline2Loc = SwingThing.IdleMoveSpline2.Spline.GetClosestSplineWorldLocationToWorldLocation(SwingThing.ActorLocation);
					if (Spline1Loc.Distance(SwingThing.ActorLocation) < Spline2Loc.Distance(SwingThing.ActorLocation))
						MoveSpline = SwingThing.IdleMoveSpline1;
					else
						MoveSpline = SwingThing.IdleMoveSpline2;
					Dist = MoveSpline.Spline.GetClosestSplineDistanceToWorldLocation(SwingThing.ActorLocation);
				}

				AccCleaningSpeed.AccelerateTo(3.0, 1.0, DeltaTime);
				FVector FutureLocation = MoveSpline.Spline.GetWorldLocationAtSplineDistance(Math::Wrap(Dist + 100, 0.0, MoveSpline.Spline.SplineLength));
				FVector TowardsNextLocation = (FutureLocation - SwingThing.ActorLocation).ConstrainToPlane(SwingThing.ActorUpVector).GetSafeNormal();
				Movement.AddVelocity(TowardsNextLocation * AccCleaningSpeed.Value);
			}
			else
				AccCleaningSpeed.SnapTo(0.0);
		}
		else
		{
			Movement.ApplyCrumbSyncedGroundMovement();
		}

		MoveComp.ApplyMove(Movement);

		BounceEventCooldown -= DeltaTime;

		if (BounceEventCooldown < 0.0)
		{
			for (auto Impact : MoveComp.AllImpacts)
			{
				if (Impact.IsWallImpact())
				{
					AHazePlayerCharacter ImpactedPlayer = Cast<AHazePlayerCharacter>(Impact.GetActor());
					if (ImpactedPlayer != nullptr) // this is special case handled in CrumbStumblePlayer && CrumbKnockPlayer
						continue;
					USkylineInnerCityHitSwingEventHandler::Trigger_OnBounceAgainstWall(SwingThing);
					BounceEventCooldown = 1.0 / 30.0;
					break;
				}
			}
		}
	}

};