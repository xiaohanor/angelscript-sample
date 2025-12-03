class UGravityBladeGrappleComponent : UAutoAimTargetComponent
{
	default TargetableCategory = n"GravityBladeGrapple";
	default UsableByPlayers = EHazeSelectPlayer::Mio;
	default MaximumDistance = GravityBladeGrapple::Range;
	default bIsAutoAimEnabled = true;
	default AutoAimMaxAngle = 30.0;

	UPROPERTY(EditAnywhere)
	bool bIsCombatGrapple = false;

	UPROPERTY(EditAnywhere)
	float MinimumDistanceFromPlayer = 0.0;
	UPROPERTY(EditAnywhere)
	float MaximumDistanceFromPlayer = 0.0;

	bool bAlwaysAirGrapple = false;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		if (bIsCombatGrapple)
		{
			if (!GravityBladeCombat::bEnableCombatGrapple)
				return false;

			// Don't allow combat grapple while the player is attacking
			auto CombatComp = UGravityBladeCombatUserComponent::Get(Query.Player);
			if (CombatComp.HasActiveAttack() && !CombatComp.bInsideSettleWindow)
				return false;

			// Don't allow grapple if the enemy is dead or dying
			auto HealthComp = UBasicAIHealthComponent::Get(Owner);
			if (HealthComp != nullptr == (HealthComp.IsDead() || HealthComp.IsDying()))
				return false;
		}

		float DistanceToPlayer = Query.Player.ActorLocation.Distance(WorldLocation);
		if (DistanceToPlayer < MinimumDistanceFromPlayer)
		{
			if (bIsCombatGrapple)
			{
				// Combat grapples only become invisible, they will be rejected by the activation capability.
				// This is because we want nearby enemies to block combat grapple targeting for other enemies
				Query.Result.bVisible = false;
			}
			else
			{
				return false;
			}
		}
		if (MaximumDistanceFromPlayer > 0.0 && DistanceToPlayer > MaximumDistanceFromPlayer)
			return false;

		// Don't allow grappling to targets if we already have the same gravity direction
		// as the grapple target.
		FVector ShiftUpVector = ForwardVector;
		if (!bIsCombatGrapple)
		{
			auto ShiftComp = UGravityBladeGravityShiftComponent::Get(Owner);
			if (ShiftComp != nullptr && ShiftComp.Type != EGravityBladeGravityShiftType::Surface)
				ShiftUpVector = ShiftComp.GetShiftDirection(WorldLocation);
			if (ShiftUpVector.DotProduct(Query.PlayerWorldUp) >= 0.99)
				return false;
		}

		UGravityBladeGrappleUserComponent GrappleComp = UGravityBladeGrappleUserComponent::Get(Query.Player);
		if(GrappleComp != nullptr && GrappleComp.Settings.bUse2DTargeting)
		{
			return TwoDimensionalTargeting(Query, GrappleComp, ShiftUpVector);
		}
		else
		{
			bool bAimResult = Super::CheckTargetable(Query);
			if (bIsCombatGrapple)
			{
				Query.Result.Score = 1.0;
				Targetable::ScoreLookAtAim(Query);
			}

			// If the point is occluded we can't target it,
			// we only do this test if we would otherwise become primary target (performance)
			Targetable::MarkVisibilityHandled(Query);
			Targetable::RequireUnobstructedLineFromPlayer(Query, KeepDistanceAmount = 50);

			return bAimResult;
		}
	}

	private bool TwoDimensionalTargeting(FTargetableQuery& Query, UGravityBladeGrappleUserComponent GrappleComp, FVector ShiftUpVector) const
	{
		if (!CullMaxDistance(Query, Query.Player.ActorLocation))
			return false;

		Targetable::ApplyVisibleRange(Query, GravityBladeGrapple::VisibleRange);
		Targetable::ApplyTargetableRange(Query, GravityBladeGrapple::Range);

		if (!Query.Result.bPossibleTarget)
			return false;

		if (bOnlyValidIfAimOriginIsWithinAngle)
		{
			// If the aim origin is outside of an aiming cone, then this target is invalid
			const FVector ToAimOrigin = Query.Player.ActorLocation - WorldLocation;
			float Angle = ForwardVector.GetAngleDegreesTo(ToAimOrigin);
			if(Angle > MaxAimAngle)
				return false;
		}

		Query.Result.Score = 1.0 / WorldLocation.Distance(Query.PlayerLocation);

		// If the point is occluded we can't target it,
		// we only do this test if we would otherwise become primary target (performance)
		if (Query.IsCurrentScoreViableForPrimary())
		{
			Targetable::MarkVisibilityHandled(Query);
			return CheckCanReachGrappleLocation(Query, ShiftUpVector);
		}

		return true;
	}

	bool CheckCanReachGrappleLocation(FTargetableQuery& Query, FVector ShiftUpVector) const
	{
		if (bIsCombatGrapple)
			return true;

		const float CapsuleRadius = Query.Player.CapsuleComponent.ScaledCapsuleRadius;
		const float CapsuleHalfHeight = Query.Player.CapsuleComponent.ScaledCapsuleHalfHeight;

		auto Trace = Trace::InitChannel(ECollisionChannel::PlayerCharacter);
		Trace.UseCapsuleShape(CapsuleRadius, CapsuleHalfHeight, FQuat::MakeFromZX(UpVector, ForwardVector));
		Trace.DebugDrawOneFrame();

		FHitResult OutCapsuleTargetHit = Trace.QueryTraceSingle(
			WorldLocation + (ShiftUpVector * (CapsuleHalfHeight + GravityBladeGrapple::PullbackDistance)),
			WorldLocation - (ShiftUpVector * (GravityBladeGrapple::StepDownHeight + GravityBladeGrapple::PullbackDistance))
		);

		if (OutCapsuleTargetHit.bStartPenetrating || !OutCapsuleTargetHit.bBlockingHit)
		{
			Query.Result.bPossibleTarget = false;
			Query.Result.bVisible = false;
			Query.Result.Score = 0.0;
			return false;
		}

		return true;
	}

	bool CheckPrimaryOcclusion(FTargetableQuery& Query, FVector TargetLocation) const override
	{
		Targetable::RequireAimToPointNotOccluded(Query, TargetLocation, IgnoredComponents, TracePullback, bIgnoreActorCollisionForAimTrace);
		return true;
	}

	private bool CullMaxDistance(FTargetableQuery& Query, FVector Location) const
	{
		if(TargetShape.Type == EHazeShapeType::Box)
		{
			// Check if the origin is too far away from the box
			float BaseDistance = DistanceFromPoint(Location);
			if (BaseDistance > MaximumDistance)
				return false;
			if (BaseDistance < MinimumDistance)
				return false;
		}
		else
		{
			// Pre-cull based on total distance, this is technically a bit inaccurate with the shape,
			// but max distances are generally so far that it doesn't matter
			float BaseDistanceSQ = WorldLocation.DistSquared(Location);
			if (BaseDistanceSQ > Math::Square(MaximumDistance))
				return false;
			if (BaseDistanceSQ < Math::Square(MinimumDistance))
				return false;
		}

		return true;
	}

	float DistanceFromPoint(FVector Point, bool bProjectToPlane = false) const
	{
		FVector RelativePoint = Point;

		if(bProjectToPlane)
			RelativePoint = Point.PointPlaneProject(WorldTransform.GetLocation(), WorldTransform.GetRotation().GetForwardVector());

		RelativePoint = WorldTransform.InverseTransformPositionNoScale(RelativePoint);

		switch(TargetShape.Type)
		{
			case EHazeShapeType::Box:
			{
				const float XDist = Math::Max(Math::Abs(RelativePoint.X) - TargetShape.BoxExtents.X, 0.0);
				const float YDist = Math::Max(Math::Abs(RelativePoint.Y) - TargetShape.BoxExtents.Y, 0.0);
				const float ZDist = Math::Max(Math::Abs(RelativePoint.Z) - TargetShape.BoxExtents.Z, 0.0);

				return XDist + YDist + ZDist;
			}
			default:
				check(false);
				return -1.0;
		}
	}

	FVector GetClosestPointTo(const FVector& Point, FAimingRay AimRay) const
	{
		FVector InternalPoint = Point;

		// Transform to AABB space
		const FVector RelativePoint = WorldTransform.InverseTransformPositionNoScale(InternalPoint);

		switch(TargetShape.Type)
		{
			case EHazeShapeType::Box:
			{
				// Project each axis onto a side of the cube
				const FVector RelativeProjectedPoint = FVector(
					Math::Min(Math::Abs(RelativePoint.X), TargetShape.BoxExtents.X) * Math::Sign(RelativePoint.X),
					Math::Min(Math::Abs(RelativePoint.Y), TargetShape.BoxExtents.Y) * Math::Sign(RelativePoint.Y),
					Math::Min(Math::Abs(RelativePoint.Z), TargetShape.BoxExtents.Z) * Math::Sign(RelativePoint.Z)
				);

				// Transform back to world space
				FVector ClosestWorldLocation = WorldTransform.TransformPositionNoScale(RelativeProjectedPoint);
				if (AimRay.HasConstraintPlane())
					ClosestWorldLocation = ClosestWorldLocation.PointPlaneProject(AimRay.Origin, AimRay.ConstraintPlaneNormal);

				return ClosestWorldLocation;
			}
			default:
				check(false);
				return FVector::ZeroVector;
		}
	}
}