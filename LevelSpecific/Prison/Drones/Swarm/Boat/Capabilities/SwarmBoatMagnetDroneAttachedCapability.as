class USwarmBoatMagnetDroneAttachedCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default TickGroup = EHazeTickGroup::AfterGameplay;

	UPlayerSwarmBoatComponent BoatComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BoatComp = UPlayerSwarmBoatComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!BoatComp.IsMagnetDroneAttached())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!BoatComp.IsMagnetDroneAttached())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CapabilityTags::FindOtherPlayer, this);
		Game::Zoe.ApplyCameraSettings(BoatComp.CameraSettings.WaterMovementSettings,1,this,EHazeCameraPriority::Medium,0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::FindOtherPlayer, this);
		Game::Zoe.ClearCameraSettingsByInstigator(this);
	}
};