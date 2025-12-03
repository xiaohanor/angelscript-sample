class UMoonMarketYarnBallMovementData : USimpleMovementData
{
	default DefaultResolverType = UMoonMarketYarnBallMovementResolver;

	float Radius;

	bool PrepareMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp) override
	{
		if(!Super::PrepareMove(MovementComponent, CustomWorldUp))
			return false;

		Radius = Cast<AMoonMarketYarnBall>(MovementComponent.Owner).Collision.ScaledSphereRadius;
		
		if(Radius < 0.05)
			Radius = 0.05;

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