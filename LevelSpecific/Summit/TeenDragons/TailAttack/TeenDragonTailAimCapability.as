class UTeenDragonTailAimCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 201;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerAimingComponent AimComp;
	UPlayerTailTeenDragonComponent DragonComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AimComp = UPlayerAimingComponent::Get(Player);
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
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
		FAimingSettings Settings;
		Settings.bShowCrosshair = false;
		Settings.OverrideCrosshairWidget = DragonComp.AttackCrosshair;
		Settings.bApplyAimingSensitivity = false;
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
		// DragonComp.DragonMesh.RequestOverrideFeature(TeenDragonLocomotionTags::AcidTeenShoot, this);
	}
}