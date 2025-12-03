class UMoonMarketPolymorphCheeseMovementData : USweepingMovementData
{
	default DefaultResolverType = UMoonMarketPolymorphCheeseMovementResolver;

	float Radius;

	bool PrepareMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp) override
	{
		if(!Super::PrepareMove(MovementComponent, CustomWorldUp))
			return false;

		Radius = 20;

		return true;
	}

#if EDITOR
	void CopyFrom(const UBaseMovementData OtherBase) override
	{
		Super::CopyFrom(OtherBase);
		Radius = Cast<UMoonMarketPolymorphCheeseMovementData>(OtherBase).Radius;
	}
#endif
}