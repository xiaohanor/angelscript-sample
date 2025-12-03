class UMoonMarketBouncyBallMovementData : USimpleMovementData
{
	default DefaultResolverType = UMoonMarketBouncyBallMovementResolver;

	AMoonMarketBouncyBall Ball;
	float Radius;
	float Bounciness = 0.4;

	bool PrepareMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp) override
	{
		if(!Super::PrepareMove(MovementComponent, CustomWorldUp))
			return false;

		return true;
	}

#if EDITOR
	void CopyFrom(const UBaseMovementData OtherBase) override
	{
		Super::CopyFrom(OtherBase);
		Radius = Cast<UMoonMarketYarnBallMovementData>(OtherBase).Radius;
	}
#endif
}