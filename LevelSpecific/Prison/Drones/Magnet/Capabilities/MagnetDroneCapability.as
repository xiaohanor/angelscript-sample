class UMagnetDroneCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UMagnetDroneComponent MagnetDroneComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MagnetDroneComp = UMagnetDroneComponent::Get(Player);
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
		if(MagnetDroneComp.MagnetDroneMovementSettings != nullptr)
			Player.ApplySettings(MagnetDroneComp.MagnetDroneMovementSettings, this, EHazeSettingsPriority::Gameplay);

		if(MagnetDroneComp.Settings.CamSettings_Default != nullptr)
			Player.ApplyCameraSettings(MagnetDroneComp.Settings.CamSettings_Default, 0, this, EHazeCameraPriority::Low);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearSettingsByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this);
	}
};