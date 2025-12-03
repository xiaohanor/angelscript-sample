class UIslandEntranceSkydiveMovementData : USweepingMovementData
{
	access Protected = protected, UIslandEntranceSkydiveMovementResolver (inherited);

	default DefaultResolverType = UIslandEntranceSkydiveMovementResolver;

	access:Protected
	bool PrepareMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp) override
	{
		if(!Super::PrepareMove(MovementComponent, CustomWorldUp))
			return false;

		return true;
	}

#if EDITOR
	access:Protected
	void CopyFrom(const UBaseMovementData OtherBase) override
	{
		Super::CopyFrom(OtherBase);
		
		UIslandEntranceSkydiveMovementData Other = Cast<UIslandEntranceSkydiveMovementData>(OtherBase);
	}
#endif
};