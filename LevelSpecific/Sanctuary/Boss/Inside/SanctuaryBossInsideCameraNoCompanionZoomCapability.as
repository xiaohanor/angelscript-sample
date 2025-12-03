class USanctuaryBossInsideCameraNoCompanionZoomCapability : UHazePlayerCapability
{
	USanctuaryBossInsideCameraNoCompanionZoomComponent Component;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Component = USanctuaryBossInsideCameraNoCompanionZoomComponent::Get(Owner);
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
		if (Component.CameraSettings != nullptr)
			Player.ApplyCameraSettings(Component.CameraSettings, 0.0, this, EHazeCameraPriority::Medium);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (Component.CameraSettings != nullptr)
			Player.ClearCameraSettingsByInstigator(this);
	}
};