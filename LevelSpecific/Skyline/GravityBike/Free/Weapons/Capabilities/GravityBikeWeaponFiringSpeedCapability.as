class UGravityBikeWeaponFiringSpeedCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::AfterGameplay;

	UGravityBikeFreeDriverComponent DriverComp;
	UGravityBikeWeaponUserComponent WeaponComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DriverComp = UGravityBikeFreeDriverComponent::Get(Player);
		WeaponComp = UGravityBikeWeaponUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!WeaponComp.HasFiredThisFrame())
			return false;

		if(GravityBikeWeapon::bDontSlowDownWhileFiringInAir)
		{
			if(DriverComp.GetGravityBike().IsAirborne.Get())
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!WeaponComp.HasFiredThisFrame())
			return true;

		if(GravityBikeWeapon::bDontSlowDownWhileFiringInAir)
		{
			if(DriverComp.GetGravityBike().IsAirborne.Get())
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UGravityBikeFreeSettings::SetMaxSpeed(DriverComp.GetGravityBike(), WeaponComp.FiringMaxSpeed, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UGravityBikeFreeSettings::ClearMaxSpeed(DriverComp.GetGravityBike(), this);
	}
};