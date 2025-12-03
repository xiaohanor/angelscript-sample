class USkylineFlyingCarMovementData : USweepingMovementData
{
	default DefaultResolverType = USkylineFlyingCarMovementResolver;

	bool PrepareMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp) override
	{
		if(!Super::PrepareMove(MovementComponent, CustomWorldUp))
			return false;

		auto FlyingCar = Cast<ASkylineFlyingCar>(MovementComponent.Owner);

		return true;
	}

#if EDITOR
	void CopyFrom(const UBaseMovementData OtherBase) override
	{
		Super::CopyFrom(OtherBase);
		
		auto Other = Cast<USkylineFlyingCarMovementData>(OtherBase);
	}
#endif
};