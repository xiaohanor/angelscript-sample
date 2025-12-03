class UMoonMarketYarnBallMovementResolver : USimpleMovementResolver
{
	default RequiredDataType = UMoonMarketYarnBallMovementData;

	UMoonMarketYarnBallMovementData MoveData;

	void PrepareResolver(const UBaseMovementData Movement) override
	{
		Super::PrepareResolver(Movement);

		MoveData = Cast<UMoonMarketYarnBallMovementData>(Movement);
	}

	EMovementResolverHandleMovementImpactResult HandleMovementImpact(
		FMovementHitResult Hit,
		EMovementResolverAnyShapeTraceImpactType ImpactType) override
	{
		//If the ball is in contact with any surface, recalculate this iterations movement data without applying the old data
		if(Bounce(IterationState, Hit))
			return EMovementResolverHandleMovementImpactResult::Skip;

		return EMovementResolverHandleMovementImpactResult::Continue;
	}

	bool Bounce(FMovementResolverState& State, FMovementHitResult MovementHit) const
	{
		//Stop bouncing if bounce is too small
		if(State.GetDelta().Velocity.DotProduct(CurrentWorldUp) > -250)
			return false;

		for(auto It : State.DeltaStates)
		{
			FMovementDelta MovementDelta = It.Value.ConvertToDelta();
			if(MovementDelta.IsNearlyZero())
				continue;

			MovementDelta = MovementDelta.Bounce(MovementHit.Normal, 0.3);

			State.OverrideDelta(It.Key, MovementDelta);
		}

		//Must add the normal, otherwise ball will be considered clipping through the ground next iteration and may bounce again
		State.CurrentLocation = MovementHit.Location + MovementHit.Normal;

		// auto YarnBall = Cast<AMoonMarketYarnBall>(Owner);
		// if(YarnBall != nullptr)
		// {
		// 	YarnBall.CrumbOnBounce();
		// }
		
		return true;
	}
}