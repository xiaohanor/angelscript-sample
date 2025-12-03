class UPinballMagnetAttractionMovementData : USweepingMovementData
{
	access Protected = protected, UPinballMagnetAttractionMovementResolver (inherited);
	access ProtectedForMovement = protected, UBaseMovementResolver (inherited), UHazeMovementComponent (inherited);
	
	default DefaultResolverType = UPinballMagnetAttractionMovementResolver;

	access:Protected
	FMagnetDroneTargetData TargetData;

	access:Protected
	bool bIsProxy = false;

	access:ProtectedForMovement
	bool PrepareProxyMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp, float DeltaTime)
	{
		if(!PrepareMove(MovementComponent, CustomWorldUp))
			return false;

		bIsProxy = true;
		IterationTime = DeltaTime;

		return true;
	}

	access:Protected
	bool PrepareMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp) override
	{
		if(!Super::PrepareMove(MovementComponent, CustomWorldUp))
			return false;

		if(MovementComponent.HasMovementControl())
		{
			const auto AttractionComp = UPinballProxyMagnetAttractionComponent::Get(MovementComponent.Owner);
			TargetData = AttractionComp.GetAttractionTarget();
		}

		bIsProxy = false;

		return true;
	}

#if EDITOR
	access:Protected
	void CopyFrom(const UBaseMovementData OtherBase) override
	{
		Super::CopyFrom(OtherBase);
		
		const auto Other = Cast<UPinballMagnetAttractionMovementData>(OtherBase);
		TargetData = Other.TargetData;
		bIsProxy = Other.bIsProxy;
	}
#endif
}