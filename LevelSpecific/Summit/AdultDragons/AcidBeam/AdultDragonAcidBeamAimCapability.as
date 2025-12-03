class UAdultDragonAcidBeamAimCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(n"AdultDragon");
	default CapabilityTags.Add(n"Aim");

	default DebugCategory = n"AdultDragon";

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 18;

	UPlayerAimingComponent AimComp;
	UPlayerAcidAdultDragonComponent DragonComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AimComp = UPlayerAimingComponent::Get(Player);
		DragonComp = UPlayerAcidAdultDragonComponent::Get(Player);
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
		Settings.bShowCrosshair = true;
		// Settings.bUseAutoAim = true;
		Settings.OverrideCrosshairWidget = DragonComp.AcidShotCrosshair;
		Settings.OverrideAutoAimTarget = UAdultDragonAcidSoftLockComponent;
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