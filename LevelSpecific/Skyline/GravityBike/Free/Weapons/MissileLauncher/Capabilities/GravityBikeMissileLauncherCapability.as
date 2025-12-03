class UGravityBikeMissileLauncherCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Input;

	UGravityBikeFreeDriverComponent DriverComp;
	UGravityBikeWeaponUserComponent WeaponComp;
	UGravityBikeMissileLauncherComponent MissileLauncherComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DriverComp = UGravityBikeFreeDriverComponent::Get(Player);
		WeaponComp = UGravityBikeWeaponUserComponent::Get(Player);
		MissileLauncherComp = UGravityBikeMissileLauncherComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!WeaponComp.HasEquipWeaponOfType(EGravityBikeWeaponType::MissileLauncher))
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!WeaponComp.HasEquipWeaponOfType(EGravityBikeWeaponType::MissileLauncher))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MissileLauncherComp.SpawnAndEquipLauncher();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MissileLauncherComp.UnequipAndDestroyLauncher();
	}
};