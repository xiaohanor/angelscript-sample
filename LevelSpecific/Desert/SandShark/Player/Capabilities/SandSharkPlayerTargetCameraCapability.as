class USandSharkPlayerTargetCameraCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	USandSharkPlayerComponent PlayerComp;

	FHazeAcceleratedFloat AccManualFraction;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = USandSharkPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return false;
		//return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ApplyCameraSettings(PlayerComp.TargetCameraSettings, 0.5, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this, 1);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		//Manual blending by changing how much these settings are applied
		AccManualFraction.AccelerateTo(1, 2, DeltaTime);
		Player.ApplyManualFractionToCameraSettings(AccManualFraction.Value, this);
	}
};