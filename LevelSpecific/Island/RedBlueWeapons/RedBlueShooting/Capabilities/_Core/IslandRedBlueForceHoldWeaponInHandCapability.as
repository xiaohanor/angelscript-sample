class UIslandRedBlueForceHoldWeaponInHandCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(IslandRedBlueWeapon::IslandRedBlueWeapon);
	default CapabilityTags.Add(IslandRedBlueWeapon::IslandRedBlueEquipped);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 125;

	UIslandRedBlueWeaponUserComponent WeaponUserComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WeaponUserComponent = UIslandRedBlueWeaponUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!WeaponUserComponent.HasEquippedWeapons())
			return false;

		if(!WeaponUserComponent.ShouldForceHoldWeaponInHand())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!WeaponUserComponent.HasEquippedWeapons())
			return true;

		if(!WeaponUserComponent.ShouldForceHoldWeaponInHand())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		WeaponUserComponent.AttachWeaponToHand(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(WeaponUserComponent.HasEquippedWeapons())
		{
			WeaponUserComponent.AttachWeaponToThigh(this);
		}
	}
}