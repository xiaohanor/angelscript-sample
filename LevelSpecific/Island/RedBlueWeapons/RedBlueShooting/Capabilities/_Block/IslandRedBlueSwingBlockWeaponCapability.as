class UIslandRedBlueSwingBlockWeaponCapability : UHazeMarkerCapability
{
	default CapabilityTags.Add(BlockedWhileIn::Swing);

	UIslandRedBlueWeaponUserComponent WeaponUserComp;
	UPlayerSwingComponent SwingComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WeaponUserComp = UIslandRedBlueWeaponUserComponent::Get(Owner);
		SwingComp = UPlayerSwingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerBlocked()
	{
		WeaponUserComp.AddHandBlocker(EIslandRedBlueWeaponHandType::Left, this);
		SwingComp.AddRightHandBlocker(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerUnblocked()
	{
		WeaponUserComp.RemoveHandBlocker(EIslandRedBlueWeaponHandType::Left, this);
		SwingComp.RemoveRightHandBlocker(this);
	}
}