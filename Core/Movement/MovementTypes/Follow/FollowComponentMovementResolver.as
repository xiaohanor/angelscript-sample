

/** 
 * 
*/
class UFollowComponentMovementResolver : UBaseMovementResolver
{
	default RequiredDataType = UFollowComponentMovementData;

	const UFollowComponentMovementData FollowData;

	FVector CurrentLocation;
	FVector DeltaToTrace;
	float PerformedMovementAmount;

	void PrepareResolver(const UBaseMovementData Movement) override
	{
		Super::PrepareResolver(Movement);
		FollowData = Cast<UFollowComponentMovementData>(Movement);

		CurrentLocation = FollowData.OriginalActorTransform.Location;
		DeltaToTrace = FollowData.DeltaStates.GetDelta().Delta;
		PerformedMovementAmount = 0;

#if !RELEASE
		// Temporal log the initial state
		FMovementResolverTemporalLogContextScope Scope(this, n"Initial");
		ResolverTemporalLog.SetTemporalLog(Movement.GetTemporalLog().Page("Follow").Page(f"Resolve Collision [Move {FollowData.FollowMoveCount}]"));
		ResolverTemporalLog.Shape(
			"StartLocation",
			FollowData.OriginalActorTransform.Location + IterationTraceSettings.CollisionShapeOffset,
			IterationTraceSettings.GetCollisionShape(),
			FollowData.OriginalActorTransform.Rotator()
		);
#endif
	}

	/**
	 * When moving 
	 */
	void ResolveTransform(FVector& OutFinalLocation, FQuat& OutFinalRotation, FVector& OutFollowVelocity)
	{
		CurrentLocation = FollowData.OriginalActorTransform.Location;
		DeltaToTrace = FollowData.DeltaStates.GetDelta().Delta;

		while(true)
		{
			if(!PrepareNextIteration())
				break;

			// Generate the movement hit result from the current movement delta
			const FHazeTraceTag TraceTag = GenerateTraceTag(n"ResolveCollision", n"ResolveTransform");
			FMovementHitResult IterationHit = QueryShapeTrace(
				CurrentLocation, 
				DeltaToTrace, 
				TraceTag);

			if(IterationHit.bBlockingHit)
			{
				if(!IterationHit.bStartPenetrating)
				{
					HandleIterationDeltaMovementImpact(IterationHit);
				}
				else
				{
					HandleIterationDeltaMovementPenetrating(IterationHit);
				}
			}
			else
			{
				HandleIterationDeltaMovementWithoutImpact();
				break;
			}
		}

		OutFinalLocation = CurrentLocation;

		// We just follow the target rotation
		// so we turn with the thing we are following
		OutFinalRotation = FollowData.TargetRotation;

		// Provide the requested move as the velocity
		// even if we hit something because
		// the thing that we are following, still has that velocity.
		OutFollowVelocity = FollowData.DeltaStates.GetDelta().Delta / IterationTime;

#if !RELEASE
		// Temporal log the final state
		FMovementResolverTemporalLogContextScope Scope(this, n"Final");
		ResolverTemporalLog.Shape(
			"FinalLocation",
			OutFinalLocation + IterationTraceSettings.CollisionShapeOffset,
			IterationTraceSettings.GetCollisionShape(),
			OutFinalRotation.Rotator()
		);
#endif
	}

	protected bool PrepareNextIteration() override
	{
		// Increase the iteration so we don't get stuck in a loop
		IterationCount++;

		Super::PrepareNextIteration();
		
		if(IterationCount > FollowData.MaxIterations)
			return false;

		const float DeltaSizeSq = DeltaToTrace.SizeSquared();
		if(DeltaSizeSq <= Math::Square(IterationTraceSettings.TraceLengthClamps.Min))
		{
			DeltaToTrace = FVector::ZeroVector;
			return false;
		}

		return true;
	}

	void HandleIterationDeltaMovementImpact(FMovementHitResult IterationHit)
	{
		PerformedMovementAmount += IterationHit.Distance;
		CurrentLocation = IterationHit.Location;

		// Store the hit, so that we can broadcast impact events
		AccumulatedImpacts.AddImpact(IterationHit);

		if(FollowData.bSlideAlongSurfaces)
		{
			ApplyImpactOnDeltas(IterationHit);
			DeltaToTrace *= (1.0 - IterationHit.Time);
		}
		else
		{
			// Stop iterating
			DeltaToTrace = FVector::ZeroVector;
		}
	}

	void HandleIterationDeltaMovementPenetrating(FMovementHitResult IterationHit)
	{
		IterationDepenetrationCount += 1;

		if(IterationHit.Normal.DotProduct(DeltaToTrace) > 0)
		{
			// We are penetrating, but the normal is pointing in the direction we want to move.
			// This means that we are actively trying to move out of it already, so just
			// ignore collision with it and trace forward.
			IterationTraceSettings.AddPermanentIgnoredPrimitive(IterationHit.Component);

			// We reduce the iteration count to allow a retracing this sweep
			IterationCount--;
			return;
		}

		if(FollowData.bUseSweepBackDepenetration)
		{
			FMovementHitResult SweepBack = QueryShapeTrace(
				CurrentLocation + DeltaToTrace, 
				-DeltaToTrace, 
				GenerateTraceTag(n"SweepBack"));

			if(SweepBack.IsValidBlockingHit())
			{
				const FVector Safety = SweepBack.Normal;
				CurrentLocation = SweepBack.Location + Safety;
				PerformedMovementAmount += (DeltaToTrace.Size() - SweepBack.Distance);
				DeltaToTrace *= SweepBack.Time;
				DeltaToTrace -= Safety;
			}
			else
			{
				CurrentLocation = ResolveStartPenetrating(IterationHit);
			}
		}
		else
		{
			HandleIterationDeltaMovementWithoutImpact();
		}
		// FB TODO: Resolving penetration is disabled at the moment, because it very often just creates chaos
		// else
		// {
		// 	CurrentLocation = ResolveStartPenetrating(IterationHit);
		// }
	}

	void HandleIterationDeltaMovementWithoutImpact()
	{
		PerformedMovementAmount += DeltaToTrace.Size();
		CurrentLocation += DeltaToTrace;

		// Stop iterating
		DeltaToTrace = FVector::ZeroVector;
	}

	void ApplyImpactOnDeltas(FMovementHitResult Impact)
	{
		const float DeltaSize = DeltaToTrace.Size();
		DeltaToTrace = DeltaToTrace.VectorPlaneProject(Impact.Normal).GetSafeNormal() * DeltaSize;
	}
}