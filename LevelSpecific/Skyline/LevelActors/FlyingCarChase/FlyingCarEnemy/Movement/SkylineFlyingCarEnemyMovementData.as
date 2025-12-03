class USkylineFlyingCarEnemyMovementData : USimpleMovementData
{
	access Resolver = private, USkylineFlyingCarEnemyMovementResolver;

	default DefaultResolverType = USkylineFlyingCarEnemyMovementResolver;

	access:Resolver
	FVector SplineForward;

	bool PrepareMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp) override
	{
		if(!Super::PrepareMove(MovementComponent, CustomWorldUp))
			return false;

		const auto CarEnemy = Cast<ASkylineFlyingCarEnemy>(MovementComponent.Owner);
		
		if(CarEnemy.Spline != nullptr)
		{
			auto SplinePosition = CarEnemy.Spline.GetClosestSplinePositionToWorldLocation(CarEnemy.ActorLocation);
			SplineForward = SplinePosition.WorldRotation.ForwardVector;
		}
		else
		{
			SplineForward = CarEnemy.ActorForwardVector;
		}

		return true;
	}

#if EDITOR
	void CopyFrom(const UBaseMovementData OtherBase) override
	{
		Super::CopyFrom(OtherBase);
		
		const auto Other = Cast<USkylineFlyingCarEnemyMovementData>(OtherBase);
		SplineForward = Other.SplineForward;
	}
#endif
};