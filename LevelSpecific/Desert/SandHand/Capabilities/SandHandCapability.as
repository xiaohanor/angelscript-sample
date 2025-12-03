class USandHandCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(SandHand::Tags::SandHand);
	default CapabilityTags.Add(SandHand::Tags::SandHandMasterCapability);

	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
	default CapabilityTags.Add(BlockedWhileIn::Crouch);
	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);
	default CapabilityTags.Add(BlockedWhileIn::Ladder);

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	USandHandPlayerComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = USandHandPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!PlayerComp.IsUsingSandHands())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!PlayerComp.IsUsingSandHands())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ApplyCameraSettings(PlayerComp.ChargeCameraSettings, 0.5, this, SubPriority = 62);
		UCameraSettings::GetSettings(Player).FOV.ApplyAsAdditive(-3.0, this, 1);

		// Default to start firing with right
		PlayerComp.bSandHandLeft = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UCameraSettings::GetSettings(Player).FOV.Clear(this, 0.5);
		Player.ClearCameraSettingsByInstigator(this, 1);
	}
}