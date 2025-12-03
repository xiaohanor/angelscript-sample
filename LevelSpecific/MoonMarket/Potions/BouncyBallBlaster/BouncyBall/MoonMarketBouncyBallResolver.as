class UMoonMarketBouncyBallMovementResolver : USimpleMovementResolver
{
	default RequiredDataType = UMoonMarketBouncyBallMovementData;

	UMoonMarketBouncyBallMovementData MoveData;

	void PrepareResolver(const UBaseMovementData Movement) override
	{
		Super::PrepareResolver(Movement);

		MoveData = Cast<UMoonMarketBouncyBallMovementData>(Movement);
	}

	EMovementResolverHandleMovementImpactResult HandleMovementImpact(
		FMovementHitResult Hit,
		EMovementResolverAnyShapeTraceImpactType ImpactType) override
	{		
		if(Cast<ABlockingVolume>(Hit.Actor) != nullptr)
		{
			IterationTraceSettings.AddPermanentIgnoredActor(Hit.Actor);
			return EMovementResolverHandleMovementImpactResult::Skip;
		}

		HandleHit(IterationState, Hit);

		//If the ball is in contact with any surface, recalculate this iterations movement data without applying the old data
		if(Bounce(IterationState, Hit))
		{
			return EMovementResolverHandleMovementImpactResult::Skip;
		}

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

			MovementDelta = MovementDelta.Bounce(MovementHit.Normal, MoveData.Bounciness);

			State.OverrideDelta(It.Key, MovementDelta);
		}

		//Must add the normal, otherwise ball will be considered clipping through the ground next iteration and may bounce again
		State.CurrentLocation = MovementHit.Location + MovementHit.Normal;
		Cast<AMoonMarketBouncyBall>(Owner).CrumbBounce(MovementHit.Actor);
		return true;
	}

	void HandleHit(FMovementResolverState& State, FMovementHitResult Hit)
	{
		auto ResponseComp = UMoonMarketBouncyBallResponseComponent::Get(Hit.Actor);
		if(ResponseComp == nullptr)
			return;

		FMoonMarketBouncyBallHitData HitData;
		HitData.ImpactPoint = Hit.ImpactPoint;
		HitData.Ball = Cast<AMoonMarketBouncyBall>(Owner);
		HitData.ImpactNormal = Hit.ImpactNormal;
		HitData.ImpactVelocity = State.GetDelta().Velocity;
		HitData.InstigatingPlayer = HitData.Ball.OwningPlayer;
		ResponseComp.Hit(HitData);
	}
}