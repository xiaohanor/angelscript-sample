asset DragonSwordCameraSettings of UHazeCameraSpringArmSettingsDataAsset
{
	SpringArmSettings.bUseCameraOffset = true;
	SpringArmSettings.CameraOffset = FVector(0.0, 0.0, 0.0);
}

class UDragonSwordCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSword);
	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordCamera);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default DebugCategory = SummitDebugCapabilityTags::DragonSword;

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;
	UDragonSwordUserComponent SwordComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwordComp = UDragonSwordUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SwordComp.IsWeaponEquipped())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SwordComp.IsWeaponEquipped())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ApplyCameraSettings(DragonSwordCameraSettings, 2, this, SubPriority = 60);
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