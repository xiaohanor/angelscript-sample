
class UMagnetDroneAttachedMovementData : USweepingMovementData
{
	access Protected = protected, UMagnetDroneAttachedMovementResolver (inherited);

	default DefaultResolverType = UMagnetDroneAttachedMovementResolver;

	access:Protected
	bool bOnlyAlignWithMagneticContacts = false;

	access:Protected
	bool bAlignWithNonMagneticFlatGround = false;

	access:Protected
	float AlignWithNonMagneticFlatGroundAngleThreshold = 0;

	access:Protected
	bool PrepareMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp = FVector::ZeroVector) override
	{
		if(!Super::PrepareMove(MovementComponent, CustomWorldUp))
			return false;
		
		const auto AttachedComp = UMagnetDroneAttachedComponent::Get(MovementComponent.Owner);

		bOnlyAlignWithMagneticContacts = AttachedComp.Settings.bOnlyAlignWithMagneticContacts;
		bAlignWithNonMagneticFlatGround = AttachedComp.Settings.bAlignWithNonMagneticFlatGround;

		if(AttachedComp.IsAttachedToSurface() && !AttachedComp.AttachedData.GetSurfaceComp().bDetachIfFloorFound)
			bAlignWithNonMagneticFlatGround = false;

		AlignWithNonMagneticFlatGroundAngleThreshold = AttachedComp.Settings.AlignWithNonMagneticFlatGroundAngleThreshold;
		return true;
	}

#if EDITOR
	access:Protected
	void CopyFrom(const UBaseMovementData OtherBase) override
	{
		Super::CopyFrom(OtherBase);

		auto Other = Cast<UMagnetDroneAttachedMovementData>(OtherBase);
		bOnlyAlignWithMagneticContacts = Other.bOnlyAlignWithMagneticContacts;
		bAlignWithNonMagneticFlatGround = Other.bAlignWithNonMagneticFlatGround;
		AlignWithNonMagneticFlatGroundAngleThreshold = Other.AlignWithNonMagneticFlatGroundAngleThreshold;
	}
#endif
}