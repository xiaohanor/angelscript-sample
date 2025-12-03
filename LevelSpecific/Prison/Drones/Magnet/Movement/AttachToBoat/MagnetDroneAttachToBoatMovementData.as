class UMagnetDroneAttachToBoatMovementData : UDroneMovementData
{
	access Protected = protected, UMagnetDroneAttachToBoatMovementResolver (inherited);

	default DefaultResolverType = UMagnetDroneAttachToBoatMovementResolver;
	
	access:Protected
	bool bHasLanded;

	access:Protected
	bool PrepareMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp) override
	{
		if(!Super::PrepareMove(MovementComponent, CustomWorldUp))
			return false;

		bCanBounce = false;

		const auto AttachToBoatComp = UMagnetDroneAttachToBoatComponent::Get(MovementComponent.Owner);
		bHasLanded = AttachToBoatComp.bHasLandedOnBoat;

		return true;
	}

#if EDITOR
	access:Protected
	void CopyFrom(const UBaseMovementData OtherBase) override
	{
		Super::CopyFrom(OtherBase);

		auto Other = Cast<UMagnetDroneAttachToBoatMovementData>(OtherBase);
		bHasLanded = Other.bHasLanded;
	}
#endif
};