struct FSplitTraversalPushableMushroomImpact
{
	FHitResult Impact;
	FVector Velocity;
};

class USplitTraversalPushableMushroomMovementResolver : UFloatingMovementResolver
{
	float BounceFactor = 0.0;
	float MinSpeedToBounce = 0.0;
	TOptional<FSplitTraversalPushableMushroomImpact> PerformedBounce;

	void PrepareResolver(const UBaseMovementData Movement) override
	{
		Super::PrepareResolver(Movement);
		
		const auto PushableMushroom = Cast<ASplitTraversalPushableMushroom>(Owner);
		BounceFactor = PushableMushroom.BounceFactor;
		MinSpeedToBounce = PushableMushroom.MinSpeedToBounce;
		PerformedBounce.Reset();
	}

	FMovementDelta GenerateIterationDelta() const override
	{
		// Only allow horizontal movement and falling
		const FMovementDelta MovementDelta = Super::GenerateIterationDelta();
		return MovementDelta.LimitToNormal(FVector::DownVector);
	}

	FMovementHitResult QueryGroundShapeTrace(FHazeMovementTraceSettings TraceSettings,
											 FVector StartLocation, FVector GroundTraceDelta,
											 FVector WorldUp,
											 FMovementResolverGroundTraceSettings GroundTraceSettings) const override
	{
		// Use a slightly smaller shape for ground tracing.
		// This prevents the shape from hitting walls that we moved into, and instead finds ground.
		FHazeMovementTraceSettings NewTraceSettings = TraceSettings;
		const FHazeTraceShape NewShape = FHazeTraceShape::MakeBox(TraceSettings.TraceShape.Extent - FVector(2));
		const FVector NewShapeOffset = TraceSettings.CollisionShapeOffset - FVector(0, 0, 1);
		NewTraceSettings.OverrideTraceShape(NewShape, NewShapeOffset);

		FMovementResolverGroundTraceSettings NewGroundTraceSettings = GroundTraceSettings;
		NewGroundTraceSettings.NormalForImpactTypeGenerationType = EMovementResolverNormalForImpactTypeGenerationType::Normal;
		return Super::QueryGroundShapeTrace(NewTraceSettings, StartLocation, GroundTraceDelta, WorldUp, NewGroundTraceSettings);
	}

	FMovementHitResult QueryShapeTrace(
		FHazeMovementTraceSettings TraceSettings,
	    FVector TraceFromLocation,
		FVector DeltaToTrace,
		FVector WorldUp,
	    FHazeTraceTag TraceTag) const override
	{
		FMovementHitResult HitResult = Super::QueryShapeTrace(TraceSettings, TraceFromLocation, DeltaToTrace, WorldUp, TraceTag);

		if(HitResult.IsWallImpact() && HitResult.ImpactNormal.DotProduct(-DeltaToTrace.GetSafeNormal()) > 0.5)
		{
			// We hit a wall, but it could just be bad collision because we are a box.
			// We need to validate!
			const FVector MoveDir = IterationState.GetDelta().Delta.GetSafeNormal();

			// Move in towards the shape center, to move away from where the wall hit happened
			FVector TowardsShapeCenter = IterationState.GetShapeCenterLocation(TraceSettings) - HitResult.ImpactPoint;
			TowardsShapeCenter = TowardsShapeCenter.GetSafeNormal2D(MoveDir);

			if(TowardsShapeCenter.IsNearlyZero())
				return HitResult;

			// Make a validation line trace back towards the wall from a better location
			FVector FromLocation = HitResult.ImpactPoint + TowardsShapeCenter;
			FromLocation -= HitResult.ImpactNormal;

			FVector ValidateDeltaToTrace = TowardsShapeCenter * -5;

			FMovementHitResult WallEdgeValidateHit =  QueryLineTrace(FromLocation, ValidateDeltaToTrace, FHazeTraceTag(n"WallEdgeValidate"));

#if !RELEASE
			ResolverTemporalLog.MovementHit(WallEdgeValidateHit, FHazeTraceShape::MakeLine(), FVector::ZeroVector);
#endif

			if(!WallEdgeValidateHit.IsValidBlockingHit())
				return HitResult;

			// Check if the validation normal is a better aligned wall than the initial trace
			const float PreviousAlignment = HitResult.ImpactNormal.DotProduct(MoveDir);
			const float NewAlignment = WallEdgeValidateHit.ImpactNormal.DotProduct(MoveDir);

			if(NewAlignment < PreviousAlignment)
				return HitResult;

			// Perform a new sweep, slightly outside where the previous one started.
			// This should go past the nasty edge and find a new, better wall
			const FVector NewTraceFromLocation = TraceFromLocation + WallEdgeValidateHit.ImpactNormal;
			const FVector NewDeltaToTrace = DeltaToTrace - WallEdgeValidateHit.ImpactNormal;
			return Super::QueryShapeTrace(TraceSettings, NewTraceFromLocation, NewDeltaToTrace, WorldUp, TraceTag);
		}

		return HitResult;
	}

	EMovementResolverHandleMovementImpactResult HandleMovementImpact(FMovementHitResult Hit, EMovementResolverAnyShapeTraceImpactType ImpactType) override
	{
		// If this was NOT an iteration sweep, i.e it was a ground trace, we ignore this impact
		if(ImpactType != EMovementResolverAnyShapeTraceImpactType::Iteration)
			return EMovementResolverHandleMovementImpactResult::Continue;
		
		// Check if we have bounced!
		if(Bounce(IterationState, Hit))
			return EMovementResolverHandleMovementImpactResult::Skip;	// If we have bounced, skip this iteration and do another one with the new velocity

		return EMovementResolverHandleMovementImpactResult::Continue;
	}

	bool Bounce(FMovementResolverState& State, FMovementHitResult MovementHit)
	{
		if(BounceFactor < KINDA_SMALL_NUMBER)
			return false;

		// The hit was not a wall, don't bounce
		if(!MovementHit.IsWallImpact())
			return false;

		const FVector CurrentVelocity = State.GetDelta().LimitToNormal(FVector::DownVector).Velocity;
		const float CurrentSpeed = Math::Abs(CurrentVelocity.DotProduct(MovementHit.Normal));

		// Our speed was too low, don't bounce
		if(CurrentSpeed < MinSpeedToBounce)
			return false;

		FSplitTraversalPushableMushroomImpact BounceData;
		BounceData.Velocity = CurrentVelocity;

		// Iterate through all the different "deltas" (velocities) on the current iteration state, and override
		// them with new velocities that are reflected off the wall
		for(auto It : State.DeltaStates)
		{
			FMovementDelta MovementDelta = It.Value.ConvertToDelta();
			if(MovementDelta.IsNearlyZero())
				continue;

			MovementDelta = MovementDelta.LimitToNormal(FVector::DownVector);

			// Project the impact normal on the ground plane, so that we don't reflect up and away from the floor
			FVector FlatNormal = MovementHit.Normal.GetSafeNormal2D(FVector::UpVector);

			// Bounce the delta off the wall normal
			MovementDelta = MovementDelta.Bounce(FlatNormal, BounceFactor);

			// Override the delta
			State.OverrideDelta(It.Key, MovementDelta);
		}

		// Store the hit in Bounces
		BounceData.Impact = MovementHit.ConvertToHitResult();
		PerformedBounce.Set(BounceData);
		
		State.CurrentLocation = MovementHit.Location;

		return true;
	}

	void ApplyResolvedData(UHazeMovementComponent MovementComponent) override
	{
		Super::ApplyResolvedData(MovementComponent);
		
		if(PerformedBounce.IsSet())
		{
			auto PushableMushroom = Cast<ASplitTraversalPushableMushroom>(Owner);
			PushableMushroom.OnImpact(PerformedBounce.Value);
		}
	}
}