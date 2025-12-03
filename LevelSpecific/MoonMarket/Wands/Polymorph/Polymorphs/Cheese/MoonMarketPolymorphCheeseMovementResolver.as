class UMoonMarketPolymorphCheeseMovementResolver : USweepingMovementResolver
{
	default RequiredDataType = UMoonMarketPolymorphCheeseMovementData;

	UMoonMarketPolymorphCheeseMovementData MoveData;

	FMovementDelta ProjectDeltaUponGroundedBlockingImpact(
        FMovementDelta DeltaState,
        FMovementHitResult Impact,
        FMovementHitResult GroundedState) const override
    {
        if(Impact.IsWallImpact())
        {
            // Just project onto the impact normal, instead of rolling along the wall impact
            // This helps us roll over low walls
            return DeltaState.GetHorizontalPart(Impact.Normal);
        }
        else
        {
            return Super::ProjectDeltaUponGroundedBlockingImpact(DeltaState, Impact, GroundedState);
        }
    }

	// void PrepareResolver(const UBaseMovementData Movement) override
	// {
	// 	Super::PrepareResolver(Movement);

	// 	MoveData = Cast<UMoonMarketPolymorphCheeseMovementData>(Movement);
	// }

	// EMovementResolverHandleMovementImpactResult HandleMovementImpact(
	// 	FMovementHitResult Hit,
	// 	EMovementResolverAnyShapeTraceImpactType ImpactType) override
	// {
	// 	//If the ball is in contact with any surface, recalculate this iterations movement data without applying the old data
	// 	// if(Bounce(IterationState, Hit))
	// 	// 	return EMovementResolverHandleMovementImpactResult::Skip;

	// 	return EMovementResolverHandleMovementImpactResult::Continue;
	// }

	// bool Bounce(FMovementResolverState& State, FMovementHitResult MovementHit) const
	// {
	// 	//Stop bouncing if bounce is too small
	// 	// if(State.GetDelta().Velocity.DotProduct(CurrentWorldUp) > -250)
	// 	// 	return false;

	// 	for(auto It : State.DeltaStates)
	// 	{
	// 		FMovementDelta MovementDelta = It.Value.ConvertToDelta();
	// 		if(MovementDelta.IsNearlyZero())
	// 			continue;

	// 		MovementDelta = MovementDelta.Bounce(MovementHit.Normal, 0.3);

	// 		State.OverrideDelta(It.Key, MovementDelta);
	// 	}

	// 	//Must add the normal, otherwise ball will be considered clipping through the ground next iteration and may bounce again
	// 	State.CurrentLocation = MovementHit.Location + MovementHit.Normal;

	// 	return true;
	// }
}