class AGravityBikeFreeApplySettingsTrigger : AApplySettingsTrigger
{
	UPROPERTY(EditInstanceOnly, Category = "Apply Setting Trigger|Camera Settings")
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UPROPERTY(EditInstanceOnly, Category = "Apply Setting Trigger|Camera Settings")
	float CameraSettingsBlend = 2.0;

	UPROPERTY(EditInstanceOnly, Category = "Apply Setting Trigger|Camera Settings")
	float CameraSettingsBlendOutTimeOverride = -1.0;

	UPROPERTY(EditInstanceOnly, Category = "Apply Setting Trigger|Camera Settings")
	EHazeCameraPriority CameraSettingsPriority = EHazeCameraPriority::VeryHigh;

	void OnPlayerEnter(AHazePlayerCharacter Player) override
	{
		if (CameraSettings != nullptr)
			Player.ApplyCameraSettings(CameraSettings, CameraSettingsBlend, this, CameraSettingsPriority);

		auto DriverComp = UGravityBikeFreeDriverComponent::Get(Player);
		if(DriverComp == nullptr)
			return;

		ApplySettingsOnActor(DriverComp.GetGravityBike(), Player);
	}

	void OnPlayerLeave(AHazePlayerCharacter Player) override
	{
		Player.ClearCameraSettingsByInstigator(this, CameraSettingsBlendOutTimeOverride);

		auto DriverComp = UGravityBikeFreeDriverComponent::Get(Player);
		if(DriverComp == nullptr)
			return;

		ClearSettingsOnActor(DriverComp.GetGravityBike());
	}
}