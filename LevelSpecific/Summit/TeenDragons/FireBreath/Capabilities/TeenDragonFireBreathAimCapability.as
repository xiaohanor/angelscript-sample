class UTeenDragonFireBreathAimCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonFireBreath);

	default TickGroup = EHazeTickGroup::Gameplay;

	UPlayerTailTeenDragonComponent DragonComp;
	UTeenDragonRollComponent RollComp;
	UPlayerAimingComponent AimComp;
	UTeenDragonFireBreathComponent FireBreathComp;
	UTeenDragonFireBreathSettings Settings;

	FVector StartLocation;
	FVector AimDirection;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
		FireBreathComp = UTeenDragonFireBreathComponent::Get(Player);
		RollComp = UTeenDragonRollComponent::Get(Player);
		Settings = UTeenDragonFireBreathSettings::GetSettings(Player);
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
		FAimingSettings AimSettings;
		AimSettings.bShowCrosshair = false;
		AimSettings.bUseAutoAim = false;
		AimSettings.bApplyAimingSensitivity = false;
		AimComp.StartAiming(FireBreathComp, AimSettings);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimComp.StopAiming(FireBreathComp);
	}
};