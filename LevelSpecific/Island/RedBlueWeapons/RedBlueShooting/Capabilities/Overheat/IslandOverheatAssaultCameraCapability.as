class UIslandRedBlueOverheatAssaultCameraCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 150;

	UIslandRedBlueWeaponUserComponent WeaponUserComponent;
	UIslandRedBlueOverheatAssaultUserComponent OverheatUserComponent;
	UIslandRedBlueOverheatAssaultSettings Settings;

	FHazeAcceleratedFloat AcceleratedAlpha;
	UCameraSettings CameraSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WeaponUserComponent = UIslandRedBlueWeaponUserComponent::Get(Player);
		OverheatUserComponent = UIslandRedBlueOverheatAssaultUserComponent::GetOrCreate(Player);
		Settings = UIslandRedBlueOverheatAssaultSettings::GetSettings(Player);
		CameraSettings = UCameraSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(WeaponUserComponent.CurrentUpgradeType != EIslandRedBlueWeaponUpgradeType::OverheatAssault)
			return false;

		if(OverheatUserComponent.OverheatAlpha == 0.0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(WeaponUserComponent.CurrentUpgradeType != EIslandRedBlueWeaponUpgradeType::OverheatAssault)
			return true;

		if(AcceleratedAlpha.Value == 0.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CameraSettings.FOV.Clear(this, 0.25);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AcceleratedAlpha.AccelerateTo(OverheatUserComponent.OverheatAlpha, Settings.FOVAccelerationDuration, DeltaTime);
		CameraSettings.FOV.ApplyAsAdditive(AcceleratedAlpha.Value * Settings.FOVMaxIncrease, this);
	}
}
