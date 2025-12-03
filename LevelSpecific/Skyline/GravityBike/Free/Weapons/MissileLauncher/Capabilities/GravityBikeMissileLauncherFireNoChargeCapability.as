class UGravityBikeMissileLauncherFireNoChargeCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"GravityBikeFreeWeaponFire");

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UGravityBikeWeaponUserComponent WeaponComp;
	UGravityBikeMissileLauncherComponent MissileLauncherComp;
	AGravityBikeMissileLauncher MissileLauncher;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WeaponComp = UGravityBikeWeaponUserComponent::Get(Player);
		MissileLauncherComp = UGravityBikeMissileLauncherComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DeactiveDuration < 2.0)
			return false;

		if(Player.IsUsingGamepad())
		{
			if (!WasActionStarted(GravityBikeWeapon::FireAction))
				return false;
		}
		else
		{
			// Left click must be fire
			if(!WasActionStarted(ActionNames::PrimaryLevelAbility))
				return false;
		}

		if (!MissileLauncherComp.IsEquipped())
			return false;

		// Inverse no charge for weapon to activate
		if (WeaponComp.HasChargeFor(MissileLauncherComp.MissileLauncher.GetChargePerShot()))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Event on bike
		auto GravityBike = UGravityBikeFreeDriverComponent::Get(Player).GetGravityBike();
		UGravityBikeFreeEventHandler::Trigger_OnWeaponFireNoCharge(GravityBike);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
}