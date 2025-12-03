asset GravityBladeCameraSettings of UHazeCameraSpringArmSettingsDataAsset
{
	SpringArmSettings.CameraOffset = FVector(0.0, 60.0, 0.0);
}

class UGravityBladeCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(GravityBladeTags::GravityBlade);
	default CapabilityTags.Add(GravityBladeTags::GravityBladeWield);
	default CapabilityTags.Add(GravityBladeTags::GravityBladeCamera);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);


	default DebugCategory = GravityBlade::DebugCategory;

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
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
		Player.ApplyCameraSettings(GravityBladeCameraSettings, 2, this, SubPriority = 60);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
}