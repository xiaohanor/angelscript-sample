class UGravityBikeWeaponCrosshairCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"GravityBikeFreeWeaponFire");

	UGravityBikeFreeDriverComponent DriverComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DriverComp = UGravityBikeFreeDriverComponent::Get(Player);
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
		DriverComp.GetGravityBike().CrosshairPivot.SetHiddenInGame(false, true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DriverComp.GetGravityBike().CrosshairPivot.SetHiddenInGame(true, true);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};