class UGravityBikeWeaponCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::AfterGameplay;

	UGravityBikeWeaponUserComponent WeaponComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WeaponComp = UGravityBikeWeaponUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!WeaponComp.HasFiredThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		const float LastFiredTime = WeaponComp.GetLastFireTime();
		if(Time::GetGameTimeSince(LastFiredTime) > GravityBikeWeapon::FiringCameraDeactivateDelay)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ApplyCameraSettings(WeaponComp.FiringCameraSettings, GravityBikeWeapon::FiringCameraApplyBlendTime, this, EHazeCameraPriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this, GravityBikeWeapon::FiringCameraClearBlendTime);
	}
};