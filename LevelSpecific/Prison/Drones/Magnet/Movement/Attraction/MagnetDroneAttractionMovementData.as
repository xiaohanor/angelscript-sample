class UMagnetDroneAttractionMovementData : USweepingMovementData
{
	access Protected = protected, UMagnetDroneAttractionMovementResolver (inherited);
	
	default DefaultResolverType = UMagnetDroneAttractionMovementResolver;

	access:Protected
	FMagnetDroneTargetData TargetData;

	access:Protected
	bool PrepareMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp) override
	{
		if(!Super::PrepareMove(MovementComponent, CustomWorldUp))
			return false;

		if(MovementComponent.HasMovementControl())
		{
			const auto AttractionComp = UMagnetDroneAttractionComponent::Get(MovementComponent.Owner);
			TargetData = AttractionComp.GetAttractionTarget();
		}

		return true;
	}

#if EDITOR
	access:Protected
	void CopyFrom(const UBaseMovementData OtherBase) override
	{
		Super::CopyFrom(OtherBase);
		
		const auto Other = Cast<UMagnetDroneAttractionMovementData>(OtherBase);
		TargetData = Other.TargetData;
	}
#endif
}