class UIslandRedBlueAutoShotgunCapability : UHazePlayerCapability
{
	UIslandRedBlueWeaponUserComponent WeaponUserComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WeaponUserComponent = UIslandRedBlueWeaponUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(WeaponUserComponent.CurrentUpgradeType != EIslandRedBlueWeaponUpgradeType::AutoShotgun)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(WeaponUserComponent.CurrentUpgradeType != EIslandRedBlueWeaponUpgradeType::AutoShotgun)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Add any model attachments here
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Remove any model attachments here
	}
}