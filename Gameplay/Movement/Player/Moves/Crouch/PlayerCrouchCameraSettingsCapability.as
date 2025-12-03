class UPlayerCrouchCameraSettingsCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Crouch);
	default CapabilityTags.Add(n"CrouchCamera");

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerCrouchComponent CrouchComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CrouchComp = UPlayerCrouchComponent::Get(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!CrouchComp.bCrouching)
			return false;

		if (!PerspectiveModeComp.IsCameraBehaviorEnabled())
			return false;

		if (PerspectiveModeComp.GetPerspectiveMode() == EPlayerMovementPerspectiveMode::SideScroller)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CrouchComp.bCrouching)
			return true;

		if (!PerspectiveModeComp.IsCameraBehaviorEnabled())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ApplyCameraSettings(CrouchComp.CameraSetting, CrouchComp.CameraSettingBlendTime, this, EHazeCameraPriority::Minimum);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this, CrouchComp.CameraSettingBlendTime);
	}
};