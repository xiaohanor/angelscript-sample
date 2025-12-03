class UIslandRedBlueContextualBlockBothWeaponsCapability : UHazeMarkerCapability
{
	default CapabilityTags.Add(BlockedWhileIn::Dash);
	default CapabilityTags.Add(BlockedWhileIn::AirJump);
	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
	default CapabilityTags.Add(BlockedWhileIn::Grapple);
	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);

	UIslandRedBlueWeaponUserComponent WeaponUserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WeaponUserComp = UIslandRedBlueWeaponUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerBlocked()
	{
		WeaponUserComp.AddHandBlocker(EIslandRedBlueWeaponHandType::Left, this);
		WeaponUserComp.AddHandBlocker(EIslandRedBlueWeaponHandType::Right, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerUnblocked()
	{
		WeaponUserComp.RemoveHandBlocker(EIslandRedBlueWeaponHandType::Left, this);
		WeaponUserComp.RemoveHandBlocker(EIslandRedBlueWeaponHandType::Right, this);
	}
}