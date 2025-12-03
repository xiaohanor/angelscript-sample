class UAdultDragonAcidProjectileAimFullscreenCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragon);
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragonAim);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 18;

	default DebugCategory = SummitDebugCapabilityTags::AdultDragon;

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
		if(!SceneView::IsFullScreen())
			return false;

		if(!DragonComp.WantsAiming())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!SceneView::IsFullScreen())
			return true;

		if(!DragonComp.WantsAiming())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FAimingSettings Settings;
		Settings.bShowCrosshair = false;
		Settings.bUseAutoAim = true;
		Settings.bCrosshairFollowsTarget = true;
		Settings.OverrideCrosshairWidget = DragonComp.AcidShotCrosshair;
		Settings.OverrideAutoAimTarget = UAdultDragonAcidAutoAimComponent;
		AimComp.StartAiming(Player, Settings);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimComp.StopAiming(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto AimResult = AimComp.GetAimingTarget(Player);
		FVector AimDirection = AimResult.AimDirection;

		// Debug::DrawDebugDirectionArrow(AimResult.AimOrigin, AimDirection, 5000, 40, FLinearColor::Red, 20);
		DragonComp.AimDirection = AimDirection;
		DragonComp.AimOrigin = AimResult.AimOrigin;
	}
};