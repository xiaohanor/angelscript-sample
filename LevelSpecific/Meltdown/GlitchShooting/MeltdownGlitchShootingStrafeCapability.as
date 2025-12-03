class UMeltdownGlitchShootingStrafeCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"GlitchShooting");

	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UMeltdownGlitchShootingUserComponent UserComp;
	UMeltdownGlitchShootingSettings Settings;
	UPlayerStrafeComponent StrafeComponent;
	UPlayerAimingComponent AimingComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UMeltdownGlitchShootingUserComponent::Get(Player);
		Settings = UMeltdownGlitchShootingSettings::GetSettings(Player);
		StrafeComponent = UPlayerStrafeComponent::GetOrCreate(Player);
		AimingComp = UPlayerAimingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!IsActioning(ActionNames::WeaponFire))
			return false;
		if (!UserComp.bGlitchShootingActive)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsActioning(ActionNames::WeaponFire))
			return true;
		if (!UserComp.bGlitchShootingActive)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StrafeComponent.SetStrafeEnabled(this, true);
		Player.ApplyStrafeSpeedScale(this, Settings.MovementSpeedWhileFiring);
		AimingComp.ApplyAimingSensitivity(this);

		Player.BlockCapabilities(PlayerMovementTags::Jump, this);
		Player.BlockCapabilities(PlayerMovementTags::Dash, this);

		UCameraSettings CamSettings = UCameraSettings::GetSettings(Player);
		// CamSettings.FOV.ApplyAsAdditive(-10.0, this, 1.0);
		// CamSettings.IdealDistance.ApplyAsAdditive(-500.0, this, 1.0, EHazeCameraPriority::MAX);
		// CamSettings.PivotOffset.ApplyAsAdditive(FVector(0.0, 100.0, 0.0), this, 1.0, EHazeCameraPriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		StrafeComponent.SetStrafeEnabled(this, false);
		Player.ClearStrafeSpeedScale(this);
		AimingComp.ClearAimingSensitivity(this);
		Player.ClearCameraSettingsByInstigator(this);

		Player.UnblockCapabilities(PlayerMovementTags::Jump, this);
		Player.UnblockCapabilities(PlayerMovementTags::Dash, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};