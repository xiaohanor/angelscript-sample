class UMeltdownGlitchBeamAimCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"Aiming");
	default CapabilityTags.Add(n"GlitchShooting");

	default TickGroup = EHazeTickGroup::Movement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UMeltdownGlitchShootingUserComponent UserComp;
	UMeltdownGlitchShootingSettings Settings;
	UPlayerAimingComponent AimingComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UMeltdownGlitchShootingUserComponent::Get(Player);
		Settings = UMeltdownGlitchShootingSettings::GetSettings(Player);
		AimingComp = UPlayerAimingComponent::Get(Player);
		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!UserComp.bGlitchShootingActive)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!UserComp.bGlitchShootingActive)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FAimingSettings AimingSettings;
		AimingSettings.bShowCrosshair = Player.GetCurrentGameplayPerspectiveMode() == EPlayerMovementPerspectiveMode::ThirdPerson;
		AimingSettings.bUseAutoAim = true;
		AimingSettings.bApplyAimingSensitivity = false;
		AimingComp.StartAiming(UserComp, AimingSettings);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimingComp.StopAiming(UserComp);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};