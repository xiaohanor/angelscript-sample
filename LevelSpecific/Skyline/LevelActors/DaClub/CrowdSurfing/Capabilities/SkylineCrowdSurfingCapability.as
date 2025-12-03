class USkylineCrowdSurfingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	USkylineCrowdSurfingUserComponent UserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = USkylineCrowdSurfingUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!UserComp.IsInCrowd())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (UserComp.HasLeftCrowd())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UserComp.IsCrowdSurfing = true;
		Player.ApplyCameraSettings(UserComp.CameraSettings, 1.0, this);

		Player.BlockCapabilities(GravityBladeCombatTags::GravityBladeCombat, this);
		Player.BlockCapabilities(PlayerMovementTags::Jump, this);
		Player.BlockCapabilities(PlayerMovementTags::Dash, this);
		Player.BlockCapabilities(PlayerMovementTags::AirDash, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UserComp.IsCrowdSurfing = false;
		Player.ClearCameraSettingsByInstigator(this);

		Player.UnblockCapabilities(GravityBladeCombatTags::GravityBladeCombat, this);
		Player.UnblockCapabilities(PlayerMovementTags::Jump, this);
		Player.UnblockCapabilities(PlayerMovementTags::Dash, this);
		Player.UnblockCapabilities(PlayerMovementTags::AirDash, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PrintToScreen("InCrowd!", 0.0, FLinearColor::Green);
	}
};