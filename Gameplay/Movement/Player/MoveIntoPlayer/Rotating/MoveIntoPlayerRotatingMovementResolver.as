struct FMoveIntoPlayerRotatingState
{
	FVector CurrentLocation = FVector::ZeroVector;
	FVector DeltaToTrace = FVector::ZeroVector;
};

/** 
 * 
*/
class UMoveIntoPlayerRotatingMovementResolver : UBaseMovementResolver
{
	default RequiredDataType = UMoveIntoPlayerRotatingMovementData;

	const UMoveIntoPlayerRotatingMovementData MoveIntoPlayerRotatingData;

	FMoveIntoPlayerRotatingState MoveIntoPlayerState;

	// Where we need to move to keep our relative offset from the moving actor
	FVector FollowDelta;

	// How much extra we should move before sweeping back
	FVector ExtrapolatedDelta;

	// The total distance we should move
	float DistanceToMove = 0;

	// The distance we have moved so far
	float PerformedMovementAmount = 0;

	// If we have redirected, we don't want to use the extrapolated delta because it's direction may be invalid
	// FB TODO: We might want to keep sweeping after a redirect, but only keep the distance of the extrapolation, not direction
	bool bHasRedirected = false;

	// We store the deltas from our Out iterations so that we can sweep back
	TArray<FVector> MoveOutDeltas;

#if !RELEASE
	default TemporalLogPageName = "MoveIntoPlayerRotating Resolver";
	const FString InitialCategory = "1. Initial";
	const FString OutCategory = "2. Out Iterations";
	const FString BackCategory = "3. Back Iterations";
	const FString FinalCategory = "4. Final";
	FString DebugMoveCategory;
#endif

	void PrepareResolver(const UBaseMovementData Movement) override
	{
		Super::PrepareResolver(Movement);

		MoveIntoPlayerRotatingData = Cast<UMoveIntoPlayerRotatingMovementData>(Movement);

		MoveIntoPlayerState.CurrentLocation = Owner.ActorLocation;
		MoveIntoPlayerState.DeltaToTrace = FVector::ZeroVector;

		FollowDelta = MoveIntoPlayerRotatingData.FollowDelta;
		ExtrapolatedDelta = MoveIntoPlayerRotatingData.ExtrapolatedDelta;

		// FVector Origin;
		// FVector Extent;
		// MoveIntoPlayerRotatingData.ShapeComponent.Owner.GetActorLocalBounds(true, Origin, Extent);

		// FB TODO: This was here to prevent being bStartPenetrating after a rotating move, but the way it was implemented was shit
		// const float MinDeltaSize = (Extent * MoveIntoPlayerRotatingData.ShapeComponent.Owner.ActorScale3D).Size() * 0.5;
		// if(ExtrapolatedDelta.SizeSquared() < Math::Square(MinDeltaSize))
		// {
		// 	// At minimum we want to sweep out the extents of the shape
		// 	// FB TODO: Instead of bounds, we should get the thickness of the shape at the distance from rotational pivot in the direction of the normal or something
		// 	ExtrapolatedDelta = ExtrapolatedDelta.GetSafeNormal() * MinDeltaSize;
		// }

		DistanceToMove = (FollowDelta + ExtrapolatedDelta).Size();
		PerformedMovementAmount = 0;
		bHasRedirected = false;

		MoveOutDeltas.Reset();

#if !RELEASE
		if(CanTemporalLog())
		{
			DebugMoveCategory = MoveIntoPlayerRotatingData.ShapeComponent.MoveCategory;
			GetTemporalLog().Status("MoveIntoPlayerRotating", FLinearColor::Green);
		}
#endif
	}

	void ResolveMoveInto(FVector&out OutLocation, FVector&out OutVelocity, const USceneComponent&out OutRelativeToComponent)
	{
#if !RELEASE
		if(CanTemporalLog())
		{
			GetTemporalLog().Section(DebugMoveCategory).Section(InitialCategory, 1)
				.Value("Move Instigator", MoveIntoPlayerRotatingData.MovementInstigator)
				.MovementShape("Current Location", MoveIntoPlayerState.CurrentLocation, IterationTraceSettings)
				.Value("Distance To Move", DistanceToMove)

				.DirectionalArrow("FollowDelta", MoveIntoPlayerState.CurrentLocation, FollowDelta)
				.DirectionalArrow("ExtrapolatedDelta", MoveIntoPlayerState.CurrentLocation + FollowDelta, ExtrapolatedDelta);
		}
#endif

		// By default, we will use the current component for relative syncing
		OutRelativeToComponent = MoveIntoPlayerRotatingData.ShapeComponent;

		// Move Out Iterations
		while(true)
		{
			if(!PrepareOutNextIteration())
				break;

			IterationTraceSettings.AddNextTraceIgnoredActor(MoveIntoPlayerRotatingData.ShapeComponent.Owner);
			const FHazeTraceTag TraceTag = GenerateTraceTag(n"MoveIntoPlayerOutIteration", n"ResolveMoveInto");
			auto OutIterationHit = QueryShapeTrace(MoveIntoPlayerState.CurrentLocation, MoveIntoPlayerState.DeltaToTrace, TraceTag);

#if !RELEASE
			if(CanTemporalLog())
			{
				GetTemporalLog().Section(DebugMoveCategory).Section(f"{OutCategory} {IterationCount :03}", 2)
					.HitResults("OutIterationHit", OutIterationHit.ConvertToHitResult(), TraceShape, IterationTraceSettings.CollisionShapeOffset, true)
					.MovementShape("StartLocation", MoveIntoPlayerState.CurrentLocation, IterationTraceSettings)
					.DirectionalArrow("Delta", MoveIntoPlayerState.CurrentLocation, MoveIntoPlayerState.DeltaToTrace)
					.Value("PerformedMovementAmount", PerformedMovementAmount);
			}
#endif

			if(OutIterationHit.bStartPenetrating)
			{
				break;
			}
			else if(OutIterationHit.bBlockingHit)
			{
				MoveOutDeltas.Add(MoveIntoPlayerState.DeltaToTrace * OutIterationHit.Time);
				bHasRedirected = true;
				HandleIterationDeltaMovementImpact(OutIterationHit);
			}
			else
			{
				MoveOutDeltas.Add(MoveIntoPlayerState.DeltaToTrace);
				HandleIterationDeltaMovementWithoutImpact();
			}
		}

		// Move Back Iterations
		int BackIterationCount = 0;

		for(int i = MoveOutDeltas.Num() - 1; i >= 0; i--)
		{
			BackIterationCount++;
			
			MoveIntoPlayerState.DeltaToTrace = -MoveOutDeltas.Last();
			MoveOutDeltas.RemoveAt(MoveOutDeltas.Num() - 1);

			if(MoveIntoPlayerState.DeltaToTrace.IsNearlyZero())
				continue;

			const FHazeTraceTag TraceTag = GenerateTraceTag(n"MoveIntoPlayerBackIteration", n"ResolveMoveInto");
			auto BackIterationHit = QueryShapeTrace(MoveIntoPlayerState.CurrentLocation, MoveIntoPlayerState.DeltaToTrace, TraceTag);

#if !RELEASE
			if(CanTemporalLog())
			{
				GetTemporalLog().Section(DebugMoveCategory).Section(f"{BackCategory} {BackIterationCount :03}", 3)
					.HitResults("BackIterationHit", BackIterationHit.ConvertToHitResult(), TraceShape, IterationTraceSettings.CollisionShapeOffset, true)
					.MovementShape("CurrentLocation", MoveIntoPlayerState.CurrentLocation, IterationTraceSettings)
					.DirectionalArrow("Delta", MoveIntoPlayerState.CurrentLocation, MoveIntoPlayerState.DeltaToTrace)
					.Value("PerformedMovementAmount", PerformedMovementAmount);
			}
#endif

			if(BackIterationHit.bStartPenetrating)
			{
				// If this occurs, we might just want ResolveStartPenetrating to handle it
				if(!bHasRedirected)
				{
					// If we used the extrapolated delta, move back to where the first delta left us to prevent going too far away
					MoveIntoPlayerState.CurrentLocation = BackIterationHit.TraceOrigin - ExtrapolatedDelta;
				}
				//DebugBreak();
				break;
			}
			else if(BackIterationHit.bBlockingHit)
			{
				if(BackIterationHit.Actor == MoveIntoPlayerRotatingData.ShapeComponent.Owner)
				{
					HandleMovementImpactInternal(BackIterationHit, EMovementResolverAnyShapeTraceImpactType::MoveIntoPlayer);

					// We hit the moving actor, so we are done
					MoveIntoPlayerState.CurrentLocation = BackIterationHit.Location;

					// Also use the hit component for synced relative position
					OutRelativeToComponent = BackIterationHit.Component;
					break;
				}
				else
				{
					HandleIterationDeltaMovementImpact(BackIterationHit);
				}
			}
			else
			{
				HandleIterationDeltaMovementWithoutImpact();
			}
		}

		OutLocation = MoveIntoPlayerState.CurrentLocation;
		OutVelocity = (OutLocation - MoveIntoPlayerRotatingData.OriginalActorTransform.Location) / IterationTime;

#if !RELEASE
		if(CanTemporalLog())
		{
			GetTemporalLog().Section(DebugMoveCategory).Section(FinalCategory, 4)
				.MovementShape("CurrentLocation", MoveIntoPlayerState.CurrentLocation, IterationTraceSettings)
			;
		}
#endif
	}

	protected bool PrepareOutNextIteration()
	{
		// Increase the iteration so we don't get stuck in a loop
		IterationCount++;

		if(IterationCount == 1)
		{
			// First iteration, we follow the moving actor
			MoveIntoPlayerState.DeltaToTrace = FollowDelta;
		}
		else if(IterationCount == 2 && !bHasRedirected)
		{
			// Second interaction, if we didn't hit anything, we extrapolate
			MoveIntoPlayerState.DeltaToTrace = ExtrapolatedDelta;
		}

		// Too many redirections
		if(IterationCount > MoveIntoPlayerRotatingData.MaxRedirectIterations)
			return false;

		// We have moved more than we were supposed to
		if(PerformedMovementAmount > DistanceToMove)
			return false;

		const float DeltaSizeSq = MoveIntoPlayerState.DeltaToTrace.SizeSquared();
		if(DeltaSizeSq <= Math::Square(IterationTraceSettings.TraceLengthClamps.Min))
		{
			// Something set our DeltaToTrace to 0, or it's too low
			return false;
		}

		return true;
	}

	void HandleIterationDeltaMovementImpact(FMovementHitResult IterationHit)
	{
		PerformedMovementAmount += IterationHit.Distance;
		MoveIntoPlayerState.CurrentLocation = IterationHit.Location;

		ApplyImpactOnDeltas(IterationHit);

		MoveIntoPlayerState.DeltaToTrace *= (1.0 - IterationHit.Time);
	}

	void HandleIterationDeltaMovementWithoutImpact()
	{
		PerformedMovementAmount += MoveIntoPlayerState.DeltaToTrace.Size();
		MoveIntoPlayerState.CurrentLocation += MoveIntoPlayerState.DeltaToTrace;

		MoveIntoPlayerState.DeltaToTrace = FVector::ZeroVector;
	}

	/**
	 * This function will change the pending delta moves
	 */
	protected void ApplyImpactOnDeltas(FMovementHitResult Impact)
	{
		const float DeltaSize = MoveIntoPlayerState.DeltaToTrace.Size();
		MoveIntoPlayerState.DeltaToTrace = MoveIntoPlayerState.DeltaToTrace.VectorPlaneProject(Impact.Normal).GetSafeNormal() * DeltaSize;
	}

#if !RELEASE
	FTemporalLog GetTemporalLog() const override
	{
		return Super::GetTemporalLog().Page("MoveIntoPlayerRotating");
	}
#endif
};