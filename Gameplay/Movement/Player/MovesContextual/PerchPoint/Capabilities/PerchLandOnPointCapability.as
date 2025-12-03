struct FPerchLandOnPointAssistSettings
{
	float BOOST_HORIZONTAL_SPEED = 200.0;
	float TRIGGER_ANGLE = 20.0;
	float STOP_ANGLE = 45.0;
	float MIN_ADJUST_FORCE = -900.0;
	float MAX_ADJUST_FORCE = 150.0;
	float MAX_HORIZONTAL_ADJUST_FORCE = 5000.0;

	float LOCK_IN_DISTANCE = 150.0;
	float LOCK_IN_TIME = 0.35;

	float LAND_TRIGGER_DISTANCE = 100.0;
	float LAND_PREDICT_DISTANCE = 140.0;
	float LAND_PREDICT_DISTANCE_SPLINE = 80.0;

	float SNAP_VERTICAL_DISTANCE = 20.0;
	float SNAP_TRIGGER_DISTANCE = 50.0;

	bool ALLOW_HORIZONTAL_LAND = true;

	FPerchLandOnPointAssistSettings(EPerchPointLandingAssistStrength Strength)
	{
		switch (Strength)
		{
			case EPerchPointLandingAssistStrength::Default:
				// Default settings configured in struct
			break;
			case EPerchPointLandingAssistStrength::Weak:
				// Override the settings for weaker perch point landings
				BOOST_HORIZONTAL_SPEED = 0.0;
				MAX_HORIZONTAL_ADJUST_FORCE = 2000.0;
				MIN_ADJUST_FORCE = -400.0;
				MAX_ADJUST_FORCE = 0.0;
				TRIGGER_ANGLE = 10.0;
				STOP_ANGLE = 30.0;
			break;
			case EPerchPointLandingAssistStrength::Minimal:
				ALLOW_HORIZONTAL_LAND = false;
				MAX_HORIZONTAL_ADJUST_FORCE = 500.0;
				LAND_TRIGGER_DISTANCE = 25.0;
				LAND_PREDICT_DISTANCE = 50.0;
				SNAP_VERTICAL_DISTANCE = 10.0;
				SNAP_TRIGGER_DISTANCE = 25.0;
			break;
		}
	}
};

class UPerchLandOnPointCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Perch);
	default CapabilityTags.Add(PlayerPerchPointTags::PerchPointLand);

	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);
	default CapabilityTags.Add(BlockedWhileIn::Ladder);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
	default CapabilityTags.Add(BlockedWhileIn::LedgeMantle);
	default CapabilityTags.Add(BlockedWhileIn::Swing);

	default BlockExclusionTags.Add(PlayerMovementExclusionTags::ExcludePerch);

	default DebugCategory = n"Movement";

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 9;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerPerchComponent PerchComp;
	UPlayerAirMotionComponent AirMotionComp;

	FPerchLandOnPointActivationParams ActiveLand;
	bool bHasLanded = false;
	const float SoftLockPerch_NecessaryInputAngle = 35;

	FVector InternalRelativeVelocity;
	FTransform PointTransform;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		PerchComp = UPlayerPerchComponent::GetOrCreate(Player);
		AirMotionComp = UPlayerAirMotionComponent::GetOrCreate(Player);

	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPerchLandOnPointActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (PerchComp.Data.bPerching)
			return false;

		if (PerchComp.Data.State != EPlayerPerchState::Inactive)
			return false;

		if (PerchComp.PerchCooldown > 0)
			return false;

		FPerchLandOnPointActivationParams WantedParams;
		if (EvaluateBestPerchLand(WantedParams))
		{
			// if (WantedParams.PerchComp.bHasConnectedSpline && WantedParams.PerchComp.ConnectedSpline.bSoftPerchLock)
			// {
			// 	//If we are attemting to land on a perch spline with SoftPerchLock enabled then check if we are inputting along the spline
			// 	if(AllowLandOnSoftLockPerchSpline(WantedParams.PerchComp.ConnectedSpline))
			// 	{
			// 		Params = WantedParams;
			// 		return true;
			// 	}
			// 	else
			// 	{
			// 		return false;
			// 	}
			// }
			// else
			{
				Params = WantedParams;
				return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPerchLandOnPointDeactivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!IsValid(ActiveLand.PerchComp))
			return true;

		if (ActiveLand.PerchComp.IsDisabledForPlayer(Player))
			return true;

		if (ActiveDuration >= ActiveLand.TimeToLand)
		{
			Params.bLandedOnPoint = true;
			return true;
		}

		if (PerchComp.Data.State != EPlayerPerchState::Inactive)
			return true;

		if (PerchComp.PerchCooldown > 0)
			return true;

		// If we hit something, we should cancel out
		if (MoveComp.HasWallContact())
			return true;
		if (MoveComp.HasImpulse())
			return true;

		if (!IsLockedIn())
		{
			// If we land ahead of time something went wrong and we should cancel,
			// but we need to make sure we didn't just land close to the point
			if (MoveComp.IsOnWalkableGround())
				return true;

			if (!IsPerchLandValid(ActiveLand))
				return true;
		}

		// TODO: Do we need to account for mid-move gravity direction changes?

		return false;
	}

	bool IsLockedIn() const
	{
		FPerchLandOnPointAssistSettings Assist(ActiveLand.PerchComp.LandingAssistStrength);
		if (ActiveLand.TimeToLand - ActiveDuration < Assist.LOCK_IN_TIME)
			return true;

		FVector DeltaToPoint = (ActiveLand.PerchComp.WorldLocation - Player.ActorLocation);
		FVector FlatDeltaToPoint = DeltaToPoint.ConstrainToPlane(MoveComp.WorldUp);
		if (FlatDeltaToPoint.Size() < Assist.LOCK_IN_DISTANCE)
			return true;

		return false;
	}

	bool EvaluateBestPerchLand(FPerchLandOnPointActivationParams& Params) const
	{
		FPerchLandOnPointActivationParams BestParams;
		float BestPerchScore = 0.0;

		FVector MoveInput = MoveComp.MovementInput;
		
		// Check for a horizontal land for each queryable point
		if (MoveComp.IsInAir() && MoveInput.Size() >= 0.1)
		{
			for (UPerchEnterByZoneComponent Zone : PerchComp.QueryZones)
			{
				if (Zone == nullptr)
					continue;
				UPerchPointComponent QueryPerch = Zone.OwningPerchPoint;
				if (QueryPerch == nullptr || QueryPerch.IsDisabledForPlayer(Player))
					continue;
				if (QueryPerch.bShouldValidateWorldUp && !QueryPerch.ValidatePlayerWorldUp(Player))
					continue;

				FPerchLandOnPointAssistSettings Assist(QueryPerch.LandingAssistStrength);
				if (!Assist.ALLOW_HORIZONTAL_LAND)
					continue;

				FTransform LandTransform = QueryPerch.GetHorizontalLandOnTransform(Player);

				FVector DeltaToPoint = (LandTransform.Location - Player.ActorLocation);
				FVector FlatDeltaToPoint = DeltaToPoint.ConstrainToPlane(MoveComp.WorldUp);
				FVector FlatDirectionToPoint = FlatDeltaToPoint.GetSafeNormal();

				// We must be holding in the general direction of the point
				float BendAngle = MoveInput.GetSafeNormal().GetAngleDegreesTo(FlatDirectionToPoint);

#if !RELEASE
				FString LogPrefix = f"{QueryPerch.Owner.ActorNameOrLabel}.{QueryPerch} Horizontal";
				TEMPORAL_LOG(this)
					.Point(f"{LogPrefix};Location", LandTransform.Location)
					.Value(f"{LogPrefix};BendAngle", BendAngle);
#endif

				if (BendAngle > Assist.TRIGGER_ANGLE)
					continue;

				float FlatDistance = FlatDeltaToPoint.Size();
				float CurrentSpeed = Player.ActorVelocity.DotProduct(FlatDirectionToPoint);

#if !RELEASE
				TEMPORAL_LOG(this)
					.Value(f"{LogPrefix};FlatDistance", FlatDistance)
					.Value(f"{LogPrefix};CurrentSpeed", CurrentSpeed)
				;
#endif

				// We can't bend to land on a point if we are airdashing
				if (FlatDistance > 30.0 && Player.IsAnyCapabilityActive(PlayerMovementTags::AirDash))
					continue;

				FVector PointVelocity = Zone.PreviousPerchWorldVelocity;
				if (QueryPerch.bIgnorePerchMovementDuringEnter)
					PointVelocity = FVector::ZeroVector;

				float PointHorizontalSpeed = -PointVelocity.DotProduct(FlatDirectionToPoint);
				float BoostSpeed = 0.0;

				// How long would it take us to reach the position of the point at normal air control?
				float TimeToTarget = Trajectory::GetTimeToReachTarget(
					FlatDistance, CurrentSpeed + PointHorizontalSpeed,
					AirMotionComp.Settings.HorizontalMoveSpeed,
					AirMotionComp.Settings.HorizontalVelocityInterpSpeed
				);

#if !RELEASE
				TEMPORAL_LOG(this)
					.Value(f"{LogPrefix};PointHorizontalSpeed", PointHorizontalSpeed)
					.Value(f"{LogPrefix};TimeToTarget", TimeToTarget)
				;
#endif

				if (TimeToTarget < 0.0)
					continue;

				// How far above or below the point will we end up if we steer towards it
				float VerticalSpeed = (Player.ActorVelocity - PointVelocity).DotProduct(MoveComp.WorldUp);
				float VerticalMovement = VerticalSpeed * TimeToTarget - MoveComp.GravityForce * TimeToTarget * TimeToTarget * 0.5;

				float VerticalOffset = -DeltaToPoint.DotProduct(MoveComp.WorldUp) + VerticalMovement;

				// We need to adjust our gravity a bit so we actually land on it at the right time
				float VerticalAdjustForce = -VerticalOffset / Math::Max(TimeToTarget, 0.01);

#if !RELEASE
				TEMPORAL_LOG(this)
					.Value(f"{LogPrefix};VerticalAdjustForce", VerticalAdjustForce)
				;
#endif

				// If our adjustment is too big we don't do it
				if (VerticalAdjustForce > Assist.MAX_ADJUST_FORCE || VerticalAdjustForce < Assist.MIN_ADJUST_FORCE)
				{
					// Try boosting our horizontal speed first before we give up on this
					BoostSpeed = Assist.BOOST_HORIZONTAL_SPEED;
					TimeToTarget = Trajectory::GetTimeToReachTarget(
						FlatDistance, CurrentSpeed + PointHorizontalSpeed,
						AirMotionComp.Settings.HorizontalMoveSpeed + BoostSpeed,
						AirMotionComp.Settings.HorizontalVelocityInterpSpeed
					);

					VerticalMovement = VerticalSpeed * TimeToTarget - MoveComp.GravityForce * TimeToTarget * TimeToTarget * 0.5;
					VerticalOffset = -DeltaToPoint.DotProduct(MoveComp.WorldUp) + VerticalMovement;
					VerticalAdjustForce = -VerticalOffset / Math::Max(TimeToTarget, 0.01);

					// If our adjustment is too big we don't do it
					if (VerticalAdjustForce > Assist.MAX_ADJUST_FORCE || VerticalAdjustForce < Assist.MIN_ADJUST_FORCE)
						continue;

#if !RELEASE
					TEMPORAL_LOG(this)
						.Value(f"{LogPrefix};BoostSpeed", BoostSpeed)
						.Value(f"{LogPrefix};BoostedTimeToTarget", TimeToTarget)
					;
#endif
				}

				// For splines we do _not_ adjust downward, only upward. The spline will take care of the falling afterward
				// if (QueryPerch.bHasConnectedSpline)
				// 	VerticalAdjustForce = Math::Max(VerticalAdjustForce, 0.0);

				// We need to adjust our horizontal velocity as well
				FVector HorizontalVelocity = (Player.ActorVelocity - PointVelocity).ConstrainToPlane(MoveComp.WorldUp);
				FVector OrthogonalVelocity = HorizontalVelocity.ConstrainToPlane(FlatDirectionToPoint);

				// Distance = Velocity * Time + Adjust * Time * Time * 0.5
				// Adjust = (-Velocity * Time) / (Time * Time * 0.5)
				// Adjust = (-Velocity) / (Time * 0.5)
				FVector HorizontalAdjust = -OrthogonalVelocity / (TimeToTarget * 0.5);

				// Calculate the targeting score
				float Score = 1.0;
				Score /= Math::Pow(Math::Max(BendAngle, 0.001), 1.0);
				Score /= Math::Pow(Math::Max(FlatDistance, 0.001), 0.5);
				Score /= Math::Pow(Math::Max(VerticalOffset, 0.001), 1.0);

#if !RELEASE
				TEMPORAL_LOG(this)
					.Value(f"{LogPrefix};Score", Score)
				;
#endif

				if (Score > BestPerchScore)
				{
					BestParams.PerchComp = QueryPerch;
					BestParams.VerticalAdjustForce = VerticalAdjustForce;
					BestParams.BoostSpeed = BoostSpeed;
					BestParams.TimeToLand = TimeToTarget;
					BestParams.HorizontalAdjustAcceleration = LandTransform.InverseTransformVectorNoScale(HorizontalAdjust);
					BestParams.bIsVerticalLand = false;
					BestParams.AddedHorizontalVelocity = -PointVelocity;

					BestPerchScore = Score;
				}
			}
		}

		if (MoveComp.IsInAir())
		{
			// Check for vertical lands for each queryable point
			for (UPerchEnterByZoneComponent Zone : PerchComp.QueryZones)
			{
				if (Zone == nullptr)
					continue;
				UPerchPointComponent QueryPerch = Zone.OwningPerchPoint;
				if (QueryPerch == nullptr || QueryPerch.IsDisabledForPlayer(Player))
					continue;
				if (QueryPerch.bShouldValidateWorldUp && !QueryPerch.ValidatePlayerWorldUp(Player))
					continue;

				FPerchLandOnPointAssistSettings Assist(QueryPerch.LandingAssistStrength);

				FTransform LandTransform = QueryPerch.GetVerticalLandOnTransform(Player);
				FVector DeltaToPoint = (LandTransform.Location - Player.ActorLocation);

				float VerticalHeight = DeltaToPoint.DotProduct(-MoveComp.WorldUp);
				
#if !RELEASE
				FString LogPrefix = f"{QueryPerch.Owner.ActorNameOrLabel}.{QueryPerch} Vertical";
				TEMPORAL_LOG(this)
					.Point(f"{LogPrefix};Location", LandTransform.Location)
					.Value(f"{LogPrefix};VerticalHeight", VerticalHeight);
#endif

				// Can only land on points from above
				if (VerticalHeight < 0.0)
					continue;

				FVector FlatDeltaToPoint = DeltaToPoint.ConstrainToPlane(MoveComp.WorldUp);
				FVector FlatDirectionToPoint = FlatDeltaToPoint.GetSafeNormal();

				float FlatDistance = FlatDeltaToPoint.Size();
				float CurrentVerticalSpeed = Player.ActorVelocity.DotProduct(MoveComp.WorldUp);

#if !RELEASE
				TEMPORAL_LOG(this)
					.Value(f"{LogPrefix};CurrentVerticalSpeed", CurrentVerticalSpeed)
					.Value(f"{LogPrefix};FlatDistance", FlatDistance)
				;
#endif

				// Must be going downward
				if (CurrentVerticalSpeed > SMALL_NUMBER)
					continue;

				// Only check if we're currently above the point
				if (FlatDistance > Assist.LAND_TRIGGER_DISTANCE)
					continue;

				// We can't land on a point if we are airdashing
				if (Player.IsAnyCapabilityActive(PlayerMovementTags::AirDash))
				{
					if (!QueryPerch.bHasConnectedSpline)
					{
						continue;
					}
					else
					{
						// If we're airdashing on top of a spline, we can still land on it
						if (VerticalHeight >= 10.0)
							continue;
					}
				}

				// How long would it take us to reach the position of the point at normal air control?
				float TimeToTarget = Trajectory::GetTimeToReachTarget(
					-VerticalHeight, CurrentVerticalSpeed,
					-MoveComp.GetGravityForce(),
				);

				// Must be somewhat straight above the point
				FVector PredictedLocation = Player.ActorLocation + Player.ActorVelocity * TimeToTarget;
				float FlatOffset = (PredictedLocation - LandTransform.Location).ConstrainToPlane(MoveComp.WorldUp).Size();

#if !RELEASE
				TEMPORAL_LOG(this)
					.Value(f"{LogPrefix};TimeToTarget", TimeToTarget)
					.Value(f"{LogPrefix};FlatOffset", FlatOffset)
				;
#endif

				if (QueryPerch.bHasConnectedSpline)
				{
					if (FlatOffset > Assist.LAND_PREDICT_DISTANCE_SPLINE)
						continue;
				}
				else
				{
					if (FlatOffset > Assist.LAND_PREDICT_DISTANCE)
						continue;
				}

				// Don't allow landing if it's very far down
				if (TimeToTarget >= 0.5)
					continue;

				// On splines if we're already hovering it we just revert to the spline's movement immediately
				if (QueryPerch.bHasConnectedSpline && FlatDistance < Assist.LAND_TRIGGER_DISTANCE)
					TimeToTarget = 0.0;

				// If we're already basically at the point, we want to land instantly
				if (VerticalHeight < 20.0)
					TimeToTarget = 0.0;

				// Calculate how much we need to adjust our horizontal velocity to land on the point
				FVector HorizOffset = Player.ActorVelocity.ConstrainToPlane(MoveComp.WorldUp) * TimeToTarget;
				FVector HorizontalAdjust = -HorizOffset.GetSafeNormal() * Trajectory::GetAccelerationToReachTarget(
					HorizOffset.Size(), TimeToTarget, 0.0
				);

				HorizontalAdjust += FlatDirectionToPoint * Trajectory::GetAccelerationToReachTarget(
					FlatDistance, TimeToTarget, 0.0
				);

#if !RELEASE
				TEMPORAL_LOG(this)
					.Value(f"{LogPrefix};HorizontalAdjust", HorizontalAdjust)
				;
#endif

				// If the needed horizontal adjustment is too much, we don't allow the landing
				if (HorizontalAdjust.Size() > Assist.MAX_HORIZONTAL_ADJUST_FORCE)
					continue;

				// Calculate the targeting score
				float Score = 1.0;
				Score /= Math::Max(FlatDistance, 0.001);
				Score /= Math::Max(TimeToTarget, 0.001);

#if !RELEASE
				TEMPORAL_LOG(this)
					.Value(f"{LogPrefix};Score", Score)
				;
#endif

				if (Score > BestPerchScore)
				{
					BestParams.PerchComp = QueryPerch;
					BestParams.VerticalAdjustForce = 0.0;
					BestParams.BoostSpeed = 0.0;
					BestParams.TimeToLand = TimeToTarget;
					BestParams.HorizontalAdjustAcceleration = LandTransform.InverseTransformVectorNoScale(HorizontalAdjust);
					BestParams.bIsVerticalLand = true;
					BestParams.AddedHorizontalVelocity = FVector::ZeroVector;

					BestPerchScore = Score;
				}
			}
		}
		
		// If we're grounded, we could be standing right on top of a point, in which case we should immediately land on it
		if (MoveComp.IsOnAnyGround())
		{
			// Check for vertical lands for each queryable point
			for (UPerchEnterByZoneComponent Zone : PerchComp.QueryZones)
			{
				if (Zone == nullptr)
					continue;
				UPerchPointComponent QueryPerch = Zone.OwningPerchPoint;
				if (QueryPerch == nullptr || QueryPerch.IsDisabledForPlayer(Player))
					continue;
				if (QueryPerch.bShouldValidateWorldUp && !QueryPerch.ValidatePlayerWorldUp(Player))
					continue;

				FPerchLandOnPointAssistSettings Assist(QueryPerch.LandingAssistStrength);

				FTransform LandTransform = QueryPerch.GetVerticalLandOnTransform(Player);
				FVector DeltaToPoint = (LandTransform.Location - Player.ActorLocation);

				float VerticalHeight = DeltaToPoint.DotProduct(-MoveComp.WorldUp);

				// Can only land on points from above
				if (Math::Abs(VerticalHeight) > Assist.SNAP_VERTICAL_DISTANCE)
					continue;

				FVector FlatDeltaToPoint = DeltaToPoint.ConstrainToPlane(MoveComp.WorldUp);
				float FlatDistance = FlatDeltaToPoint.Size();

				// Only check if we're currently above the point
				if (FlatDistance > Assist.SNAP_TRIGGER_DISTANCE)
					continue;

				// Calculate the targeting score
				float Score = 10000.0;
				Score /= Math::Max(FlatDistance, 0.001);

				if (Score > BestPerchScore)
				{
					BestParams.PerchComp = QueryPerch;
					BestParams.VerticalAdjustForce = 0.0;
					BestParams.BoostSpeed = 0.0;
					BestParams.TimeToLand = 0.0;
					BestParams.HorizontalAdjustAcceleration = FVector::ZeroVector;
					BestParams.bIsVerticalLand = true;
					BestParams.AddedHorizontalVelocity = FVector::ZeroVector;

					BestPerchScore = Score;
				}
			}
		}

		if (BestParams.PerchComp != nullptr)
		{
			/**
				NOTE [LV]: Not sure if we actually want to do this trace, it might break in too many
				cases (perch splines hovering over things) and we only need it for one case that can be fixed differently.

			// Make sure we can actually reach the perch point without being obstructed by something
			FHazeTraceSettings Trace;
			Trace.TraceWithPlayer(Player);
			Trace.IgnoreActor(BestParams.PerchComp.Owner.AttachmentRootActor);

			FHitResult Hit = Trace.QueryTraceSingle(
				Player.ActorLocation, BestParams.PerchComp.WorldLocation
			);

			if (Hit.bBlockingHit)
				return false;
			*/

			Params = BestParams;
			return true;
		}

		return false;
	}

	bool IsPerchLandValid(FPerchLandOnPointActivationParams Params) const
	{
		// If we are giving input away from the perch point, we stop the landing
		FVector MoveInput = MoveComp.MovementInput;
		if (MoveInput.Size() > 0.1)
		{
			FVector DeltaToPoint = (Params.PerchComp.WorldLocation - Player.ActorLocation);
			FVector FlatDirectionToPoint = DeltaToPoint.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();

			FPerchLandOnPointAssistSettings Assist(Params.PerchComp.LandingAssistStrength);

			if (MoveInput.GetSafeNormal().GetAngleDegreesTo(FlatDirectionToPoint) > Assist.STOP_ANGLE)
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPerchLandOnPointActivationParams Params)
	{
		ActiveLand = Params;
		ActiveLand.PerchComp.IsPlayerLandingOnPoint[Player] = true;
		if (Params.bIsVerticalLand)
			ActiveLand.PerchComp.WorldTransform = ActiveLand.PerchComp.GetVerticalLandOnTransform(Player);
		else
			ActiveLand.PerchComp.WorldTransform = ActiveLand.PerchComp.GetHorizontalLandOnTransform(Player);
		bHasLanded = false;
		InternalRelativeVelocity = Params.PerchComp.WorldTransform.InverseTransformVectorNoScale(Player.ActorVelocity + Params.AddedHorizontalVelocity);
		PointTransform = ActiveLand.PerchComp.WorldTransform;

		// Land immediately if we want instant landing
		if (ActiveLand.TimeToLand <= 0.0)
		{
			if (!ActiveLand.PerchComp.bHasConnectedSpline)
				Player.RootOffsetComponent.FreezeRelativeTransformAndLerpBackToParent(this, ActiveLand.PerchComp, 0.2);
			TriggerPerch();
			ActiveLand = FPerchLandOnPointActivationParams();
		}
		else if (!ActiveLand.PerchComp.bIgnorePerchMovementDuringEnter)
		{
			MoveComp.FollowComponentMovement(ActiveLand.PerchComp, this);

			// If we're landing on a perch spline, the perch point itself won't be in the same location on both sides,
			// so we sync relative to the spline instead
			if (ActiveLand.PerchComp.bHasConnectedSpline && ActiveLand.PerchComp.ConnectedSpline != nullptr)
				MoveComp.ApplyCrumbSyncedRelativePosition(this, ActiveLand.PerchComp.ConnectedSpline.Spline);
		}

		Player.BlockCapabilities(PlayerMovementTags::UnwalkableSlide, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPerchLandOnPointDeactivationParams Params)
	{
		// Clear the jump button so we don't accidentally jump off immediately
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementJump);
		Player.UnblockCapabilities(PlayerMovementTags::UnwalkableSlide, this);
		MoveComp.UnFollowComponentMovement(this);
		MoveComp.ClearCrumbSyncedRelativePosition(this);

		if (ActiveLand.PerchComp != nullptr)
			ActiveLand.PerchComp.IsPlayerLandingOnPoint[Player] = false;

		if (Params.bLandedOnPoint && ActiveLand.TimeToLand > 0.0)
		{
			bool bSmoothTeleport = false;

			if (!ActiveLand.PerchComp.bHasConnectedSpline)
			{
				if (ActiveLand.TimeToLand < 0.1)
					bSmoothTeleport = true;
				if (ActiveLand.PerchComp.WorldLocation.Distance(Player.ActorLocation) > 10.0)
					bSmoothTeleport = true;
			}

			if (bSmoothTeleport)
				Player.RootOffsetComponent.FreezeRelativeTransformAndLerpBackToParent(this, ActiveLand.PerchComp, 0.1);

			TriggerPerch();
			UPlayerCoreMovementEffectHandler::Trigger_Perch_LandOnPoint(Player);
		}
	}

	void TriggerPerch()
	{
		PerchComp.AnimData.bLanding = false;
		ActiveLand.PerchComp.IsPlayerLandingOnPoint[Player] = false;
		PerchComp.Data.TargetedPerchPoint = ActiveLand.PerchComp;

		if (ActiveLand.PerchComp.bHasConnectedSpline)
		{
			PerchComp.StartPerching(ActiveLand.PerchComp, false);
			PerchComp.bIsLandingOnSpline = true;
			PerchComp.Data.bInPerchSpline = true;
		}
		else
		{
			PerchComp.StartPerching(ActiveLand.PerchComp, true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveLand.TimeToLand <= 0.0)
			return;

		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				if (!ActiveLand.PerchComp.bIgnorePerchMovementDuringEnter)
					PointTransform = ActiveLand.PerchComp.WorldTransform;

				FVector FrameWorldDelta;
				
				if (!ActiveLand.bIsVerticalLand)
				{
					FVector RelativeWorldUp = PointTransform.InverseTransformVectorNoScale(MoveComp.WorldUp);
					FVector RelativeDeltaToPoint = PointTransform.InverseTransformPosition(Player.ActorLocation);
					FVector RelativeFlatDirectionToPoint = -RelativeDeltaToPoint.ConstrainToPlane(RelativeWorldUp).GetSafeNormal();

					FVector TowardVelocity = InternalRelativeVelocity.ConstrainToDirection(RelativeFlatDirectionToPoint);
					FVector OrthogonalVelocity = InternalRelativeVelocity.ConstrainToPlane(RelativeFlatDirectionToPoint);
					FVector OriginalTowardVelocity = TowardVelocity;

					// Lerp up the velocity towards the point
					TowardVelocity = Math::VInterpConstantTo(
						TowardVelocity,
						RelativeFlatDirectionToPoint * (AirMotionComp.Settings.HorizontalMoveSpeed + ActiveLand.BoostSpeed),
						DeltaTime, AirMotionComp.Settings.HorizontalVelocityInterpSpeed);

					InternalRelativeVelocity = TowardVelocity + OrthogonalVelocity;

					TEMPORAL_LOG(this)
						.Value("RelativeDeltaToPoint", RelativeDeltaToPoint)
						.Value("RelativeDistanceToPoint", RelativeDeltaToPoint.Size())
						.Value("OriginalTowardVelocity", TowardVelocity)
						.Value("TowardVelocity", TowardVelocity)
						.Value("TowardSpeed", TowardVelocity.Size())
						.Value("TargetTowardSpeed", AirMotionComp.Settings.HorizontalMoveSpeed + ActiveLand.BoostSpeed)
						.Value("OrthogonalVelocity", OrthogonalVelocity)
						.Value("OrthogonalSpeed", OrthogonalVelocity.Size())
					;
				}

				FrameWorldDelta += PointTransform.TransformVectorNoScale(InternalRelativeVelocity) * DeltaTime;
				FrameWorldDelta += PointTransform.TransformVectorNoScale(ActiveLand.HorizontalAdjustAcceleration) * DeltaTime * DeltaTime * 0.5;
				InternalRelativeVelocity += ActiveLand.HorizontalAdjustAcceleration * DeltaTime;

				FrameWorldDelta += MoveComp.WorldUp * ActiveLand.VerticalAdjustForce * DeltaTime;
				FrameWorldDelta += MoveComp.GetGravity() * DeltaTime * DeltaTime * 0.5;
				InternalRelativeVelocity += PointTransform.InverseTransformVectorNoScale(MoveComp.GetGravity()) * DeltaTime;

#if !RELEASE
				TEMPORAL_LOG(this)
					.Value("HorizontalAdjustAcceleration", ActiveLand.HorizontalAdjustAcceleration)
					.Value("AddedHorizontalVelocity", ActiveLand.AddedHorizontalVelocity)
					.Value("VerticalAdjustForce", ActiveLand.VerticalAdjustForce)
					.Value("StartRelativeLocation", PointTransform.InverseTransformPosition(Player.ActorLocation))
					.Value("TimeToLand", ActiveLand.TimeToLand)
					.Value("FrameWorldDelta", FrameWorldDelta)
					.Value("FrameSpeed", FrameWorldDelta / DeltaTime)
					.Value("InternalRelativeVelocity", InternalRelativeVelocity)
					.Value("InternalWorldVelocity", PointTransform.TransformVectorNoScale(InternalRelativeVelocity))
				;
#endif

				Movement.AddDeltaWithCustomVelocity(FrameWorldDelta, PointTransform.TransformVectorNoScale(InternalRelativeVelocity));

				/*
					Calculate how fast the player should rotate when falling at fast speeds
				*/
				const float CurrentFallingSpeed = Math::Max((-MoveComp.WorldUp).DotProduct(MoveComp.VerticalVelocity), 0.0);
				const float RotationSpeedAlpha = Math::Clamp((CurrentFallingSpeed - AirMotionComp.Settings.MaximumTurnRateFallingSpeed) / AirMotionComp.Settings.MinimumTurnRateFallingSpeed, 0.0, 1.0);

				const float FacingDirectionInterpSpeed = Math::Lerp(AirMotionComp.Settings.MaximumTurnRate, AirMotionComp.Settings.MinimumTurnRate, RotationSpeedAlpha);
				Movement.InterpRotationToTargetFacingRotation(FacingDirectionInterpSpeed * MoveComp.MovementInput.Size());
				Movement.IgnoreSplineLockConstraint();
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			Movement.RequestFallingForThisFrame();
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"AirMovement");
		}
	}

	bool AllowLandOnSoftLockPerchSpline(APerchSpline PerchSpline) const
	{
		float SplineDistance = PerchSpline.Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation); 
		FVector SplineLocation = PerchSpline.Spline.GetWorldLocationAtSplineDistance(SplineDistance);

		FVector NonLockedMoveInput = MoveComp.GetNonLockedMovementInput().ConstrainToPlane(MoveComp.WorldUp);

		if(NonLockedMoveInput.IsNearlyZero())
			NonLockedMoveInput = Player.ActorForwardVector;

		float Angle = Math::RadiansToDegrees(NonLockedMoveInput.AngularDistanceForNormals(PerchSpline.Spline.GetWorldTangentAtSplineDistance(PerchSpline.Spline.GetClosestSplineDistanceToWorldLocation(SplineLocation)).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal()));
		float BackwardsAngle = Math::RadiansToDegrees(NonLockedMoveInput.AngularDistanceForNormals(-PerchSpline.Spline.GetWorldTangentAtSplineDistance(PerchSpline.Spline.GetClosestSplineDistanceToWorldLocation(SplineLocation)).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal()));

		if(Angle >= SoftLockPerch_NecessaryInputAngle && BackwardsAngle >= SoftLockPerch_NecessaryInputAngle)
		{
			return false;
		}
		else
			return true;
	}
}

struct FPerchLandOnPointActivationParams
{
	UPerchPointComponent PerchComp;
	float TimeToLand = 0.0;
	float VerticalAdjustForce = 0.0;
	FVector AddedHorizontalVelocity;
	FVector HorizontalAdjustAcceleration;
	float BoostSpeed = 0.0;
	bool bIsVerticalLand = false;
}

struct FPerchLandOnPointDeactivationParams
{
	bool bLandedOnPoint = false;
}