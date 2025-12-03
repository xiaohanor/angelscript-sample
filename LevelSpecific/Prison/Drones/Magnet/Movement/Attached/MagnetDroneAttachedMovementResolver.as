/** 
 * A custom SweepingMovement derived resolver to handle constraining the player to magnetic zones.
*/
class UMagnetDroneAttachedMovementResolver : USweepingMovementResolver
{
	default RequiredDataType = UMagnetDroneAttachedMovementData;
	private const UMagnetDroneAttachedMovementData MagnetSweepingData;

	void PrepareResolver(const UBaseMovementData Movement) override
	{
		Super::PrepareResolver(Movement);
		MagnetSweepingData = Cast<UMagnetDroneAttachedMovementData>(Movement);
	}

	bool PrepareNextIteration() override
	{
		const bool bResult = Super::PrepareNextIteration();

		ConstrainDeltaToWithinMagneticZone();

		return bResult;
	}

	FVector GetUnhinderedPendingLocation() const override
	{
		FVector PendingLocation = IterationState.CurrentLocation + IterationState.DeltaToTrace;

		// Spline up is broken with custom world up, so no spline locking here!
		// FB TODO: Fix this in the spline resolver!

		return PendingLocation;
	}

	FMovementHitResult GenerateDefaultGroundedState(
		FHitResult Hit,
		FVector WorldUp,
		FHazeTraceTag TraceTag,
		FVector CustomImpactNormal,
		float FlatBottomRadius) const override
	{
		FMovementHitResult Out = Super::GenerateDefaultGroundedState(Hit, WorldUp, TraceTag, CustomImpactNormal, FlatBottomRadius);

		if(!Out.IsValidBlockingHit())
			return Out;

		if(!Out.bIsWalkable)
			return Out;

		if(MagnetDrone::IsHitMagnetic(Hit, true))
		{
			// What we hit was magnetic, so force whatever it was to be ground!
			Out.Type = EMovementImpactType::Ground;
			return Out;
		}
		else
		{
			if(MagnetSweepingData.bAlignWithNonMagneticFlatGround)
			{
				const float AngleToGlobalUp = Hit.Normal.GetAngleDegreesTo(FVector::UpVector);
				if(AngleToGlobalUp < MagnetSweepingData.AlignWithNonMagneticFlatGroundAngleThreshold)
				{
					// This non-magnetic ground should be our new ground, because we want to drop off to it
					Out.Type = EMovementImpactType::Ground;
					return Out;
				}
			}

			Out.bIsWalkable = false;
			Out.Type = EMovementImpactType::Wall;
			return Out;
		}
	}

	private void ConstrainDeltaToWithinMagneticZone()
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"ConstrainDeltaToWithinMagneticZone");
#endif

		// If we don't have a ground, we can't find constraint zones
		if(!IterationState.PhysicsState.GroundContact.IsValidBlockingHit())
			return;

		if(IterationState.DeltaToTrace.IsNearlyZero())
			return;

		// Check if the current surface is
		// If the drone is not attached to a magnetic surface, no need to adjust
		auto SurfaceComp = UDroneMagneticSurfaceComponent::Get(IterationState.PhysicsState.GroundContact.Actor);
		if(SurfaceComp == nullptr)
			return;

		// Stop the player if it's trying to move out of a constrained zone
		FVector TargetLocation = IterationState.CurrentLocation + IterationState.DeltaToTrace;

		bool bConstrainedToOutside = false;
		bool bConstrainedToWithin = false;

		if(DepenetrateFromConstrainOutsideZones(TargetLocation, SurfaceComp, IterationState.DeltaToTrace))
		{
			// Reset the target location if we depenetrated
			TargetLocation = IterationState.CurrentLocation + IterationState.DeltaToTrace;
			bConstrainedToOutside = true;
		}

		UDroneMagneticZoneComponent ClosestZone = nullptr;
		if(TryGetConstrainToWithinZoneAtPoint(TargetLocation, SurfaceComp, ClosestZone))
		{
#if !RELEASE
			ResolverTemporalLog.Point("Point", TargetLocation);
			ResolverTemporalLog.Value("ClosestZone", ClosestZone);
#endif

			FVector ConstrainedTargetLocation = ClosestZone.GetClosestPointTo(TargetLocation);
			const FVector ConstrainedTargetHorizontalLocation = ConstrainedTargetLocation.VectorPlaneProject(CurrentWorldUp);
			const FVector OriginalVerticalLocation = IterationState.CurrentLocation.ProjectOnToNormal(CurrentWorldUp);
			ConstrainedTargetLocation = ConstrainedTargetHorizontalLocation + OriginalVerticalLocation;

#if !RELEASE
			ResolverTemporalLog.Point("ConstrainedTargetLocation", ConstrainedTargetLocation);
#endif

			bConstrainedToWithin = true;

			// Adjust the delta trace to stay in the constrained area
			IterationState.DeltaToTrace = ConstrainedTargetLocation - IterationState.CurrentLocation;

#if !RELEASE
			ResolverTemporalLog.DirectionalArrow("Constrained Delta", IterationState.CurrentLocation, IterationState.DeltaToTrace);
#endif
		}

		if(bConstrainedToOutside || bConstrainedToWithin)
		{
			FVector OldDelta = IterationState.GetDelta(EMovementIterationDeltaStateType::Movement).Delta;
			FVector NewVelocity = IterationState.DeltaToTrace / IterationTime;
			FMovementDelta NewDelta = FMovementDelta(OldDelta, NewVelocity);
			IterationState.OverrideDelta(EMovementIterationDeltaStateType::Movement, NewDelta);
		}
	}

	private bool DepenetrateFromConstrainOutsideZones(FVector Point, UDroneMagneticSurfaceComponent MagneticSurfaceComponent, FVector& DeltaToTrace) const
	{
		FVector DepenetrationDelta = FVector::ZeroVector;
		int DepenatrationZones = 0;

		for(auto Zone : MagneticSurfaceComponent.MagneticZones)
		{
			if(Zone.GetZoneType() != EMagnetDroneZoneType::ConstrainToOutside)
				continue;

#if !RELEASE
			if(!MagnetSweepingData.IsRerun() && DevToggleMagnetDrone::DrawValidatedUp.IsEnabled())
			{
				Debug::DrawDebugDirectionArrow(IterationState.CurrentLocation, IterationState.PhysicsState.GroundContact.ImpactNormal, 150, 10, FLinearColor::Red, 5);
				Debug::DrawDebugDirectionArrow(Zone.WorldLocation, Zone.ForwardVector, 100, 10, FLinearColor::Green, 5);
			}
#endif

			if(!Zone.IsRelevantForWorldUp(IterationState.PhysicsState.GroundContact.ImpactNormal))
				continue;

			float DistanceToPoint = Zone.DistanceFromPoint(Point, true);
			if(DistanceToPoint <= KINDA_SMALL_NUMBER)
			{
				DepenatrationZones++;
				DepenetrationDelta += Zone.Depenetrate(Point, true);
			}
		}

		if(DepenatrationZones > 0)
		{
			DepenetrationDelta /= DepenatrationZones;
			DeltaToTrace += DepenetrationDelta;
		}

		return DepenatrationZones > 0;
	}

	/**
	 * @return true if Point is within a ConstrainToWithin zone.
	 */
	private bool TryGetConstrainToWithinZoneAtPoint(FVector Point, UDroneMagneticSurfaceComponent MagneticSurfaceComponent, UDroneMagneticZoneComponent& OutClosestZone) const
	{
		bool bShouldConstrain = false;
		float ClosestZoneDistance = BIG_NUMBER;

		for(auto Zone : MagneticSurfaceComponent.MagneticZones)
		{
			if(Zone.GetZoneType() != EMagnetDroneZoneType::ConstrainToWithin)
				continue;

#if !RELEASE
			if(!MagnetSweepingData.IsRerun() && DevToggleMagnetDrone::DrawValidatedUp.IsEnabled())
			{
				Debug::DrawDebugDirectionArrow(IterationState.CurrentLocation, IterationState.PhysicsState.GroundContact.ImpactNormal, 150, 10, FLinearColor::Red, 5);
				Debug::DrawDebugDirectionArrow(Zone.WorldLocation, Zone.ForwardVector, 100, 10, FLinearColor::Green, 5);
			}
#endif

			if(!Zone.IsRelevantForWorldUp(IterationState.PhysicsState.GroundContact.ImpactNormal))
				continue;

			float DistanceToTarget = Zone.DistanceFromPoint(Point, true);

			if(DistanceToTarget < ClosestZoneDistance)
			{
				ClosestZoneDistance = DistanceToTarget;
				OutClosestZone = Zone;

				float DistanceToCurrentLocation = Zone.DistanceFromPoint(IterationState.CurrentLocation, true);
				if(DistanceToCurrentLocation > MagnetSweepingData.ShapeSizeForMovement)
					continue;	// Player is currently outside the zone, so constraining would cause teleporting

				bShouldConstrain = true;
			}
		}

		return bShouldConstrain;
	}
}