class UIslandRedBlueStickyGrenadeActiveCapability : UHazePlayerCapability
{
	UIslandRedBlueStickyGrenadeUserComponent GrenadeUserComp;
	UIslandRedBlueWeaponUserComponent WeaponUserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GrenadeUserComp = UIslandRedBlueStickyGrenadeUserComponent::Get(Player);
		WeaponUserComp = UIslandRedBlueWeaponUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		GrenadeUserComp.bInternal_GrenadeSheetIsActive = true;
		WeaponUserComp.SwitchWeaponMesh(EIslandRedBlueWeaponMeshType::GrenadeAttachmentWeapon);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GrenadeUserComp.bInternal_GrenadeSheetIsActive = false;
		WeaponUserComp.SwitchWeaponMesh(EIslandRedBlueWeaponMeshType::DefaultWeapon);
	}
}