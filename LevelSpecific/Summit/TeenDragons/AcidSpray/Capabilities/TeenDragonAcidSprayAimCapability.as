class UTeenDragonAcidSprayAimCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonAcidSpray);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonAcidSprayAim);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 201;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerAimingComponent AimComp;
	UPlayerAcidTeenDragonComponent DragonComp;
	UTeenDragonAcidSprayComponent SprayComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AimComp = UPlayerAimingComponent::Get(Player);
		DragonComp = UPlayerAcidTeenDragonComponent::Get(Player);
		SprayComp = UTeenDragonAcidSprayComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(DragonComp.AimMode != ETeenDragonAcidAimMode::AlwaysOn)
			return false;

		if(DragonComp.bTopDownMode)
			return false;

		if(AimComp.IsAiming())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(DragonComp.bTopDownMode)
			return true;

		if(DragonComp.AimMode != ETeenDragonAcidAimMode::AlwaysOn)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FAimingSettings Settings;
		Settings.bShowCrosshair = true;
		Settings.bUseAutoAim = true;
		Settings.OverrideCrosshairWidget = SprayComp.AcidSprayCrosshair;
		Settings.bApplyAimingSensitivity = false;
		Settings.bCrosshairFollowsTarget = true;
		Settings.OverrideAutoAimTarget = UTeenDragonAcidAutoAimComponent;
		AimComp.StartAiming(DragonComp, Settings);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimComp.StopAiming(DragonComp);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		
	}
}