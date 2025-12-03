class USummitBallMovementResolver : USweepingMovementResolver
{
	default RequiredDataType = USummitBallMovementData;

	const float BounceRestitution = 0.4;

	EMovementResolverHandleMovementImpactResult HandleMovementImpact(FMovementHitResult Hit,
																	 EMovementResolverAnyShapeTraceImpactType ImpactType) override
	{
		if(ImpactType == EMovementResolverAnyShapeTraceImpactType::Iteration)
		{
			if(Bounce(IterationState, Hit))
				return EMovementResolverHandleMovementImpactResult::Skip;
		}

		return EMovementResolverHandleMovementImpactResult::Continue;
	}

	bool Bounce(FMovementResolverState& State, FMovementHitResult Hit) const
	{
		if(!Hit.IsValidBlockingHit())
			return false;
		
		if(!Hit.IsWallImpact())
			return false;

		auto NonBounceComp = USummitBallNonBounceComponent::Get(Hit.Actor);
		if(NonBounceComp != nullptr)
			return false;

		auto TotalDelta = State.GetDelta();
		FVector Velocity = TotalDelta.Velocity;

		auto TempLog = TEMPORAL_LOG(Owner, "Ball Resolver");
		
		float SpeedTowardsWall = Velocity.DotProduct(-Hit.Normal);
		TempLog
			.DirectionalArrow("Bounce Normal", Hit.ImpactPoint, Hit.Normal * 500, 20, 500, FLinearColor::Blue)
			.Value("Speed", SpeedTowardsWall)
		;

		for(auto It : State.DeltaStates)
		{
			FMovementDelta Delta = It.Value.ConvertToDelta();

			Delta = Delta.Bounce(Hit.Normal, BounceRestitution);
			State.OverrideDelta(It.Key, Delta);
		}

		return true;
	}
}