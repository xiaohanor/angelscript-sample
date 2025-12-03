class UGravityBikeFreeMovementData : UFloatingMovementData
{
	access Protected = protected, UGravityBikeFreeMovementResolver (inherited);

	default DefaultResolverType = UGravityBikeFreeMovementResolver;

	access:Protected
	bool PrepareMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp = FVector::ZeroVector) override
	{
		if(!Super::PrepareMove(MovementComponent, CustomWorldUp))
			return false;
		
		bAllowSubStep = false;
		EdgeHandling = EMovementEdgeHandlingType::Leave;

		auto GravityBike = Cast<AGravityBikeFree>(MovementComponent.Owner);

		return true;
	}

#if EDITOR
	access:Protected
	void CopyFrom(const UBaseMovementData OtherBase) override
	{
		Super::CopyFrom(OtherBase);

		const UGravityBikeFreeMovementData Other = Cast<UGravityBikeFreeMovementData>(OtherBase);
	}
#endif
}