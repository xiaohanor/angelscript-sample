class UAdultDragonSpikeAimCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragon);
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragonAim);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 18;

	default DebugCategory = SummitDebugCapabilityTags::AdultDragon;

	UPlayerAimingComponent AimComp;
	UPlayerTailAdultDragonComponent DragonComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AimComp = UPlayerAimingComponent::Get(Player);
		DragonComp = UPlayerTailAdultDragonComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(SceneView::IsFullScreen())
			return false;

		if(!DragonComp.WantsAiming())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(SceneView::IsFullScreen())
			return true;

		if(!DragonComp.WantsAiming())
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		//JOHN - experimenting a little with moving the aim slightly down
		UPlayerAimingSettings::SetScreenSpaceAimOffset(Player, FVector2D(FVector2D(0.0, 0.01)), this, EHazeSettingsPriority::Gameplay);

		FAimingSettings Settings;
		Settings.bShowCrosshair = true;
		Settings.bUseAutoAim = true;
		Settings.bCrosshairFollowsTarget = true;
		Settings.OverrideCrosshairWidget = DragonComp.SpikeShotCrosshair;
		Settings.OverrideAutoAimTarget = UAdultDragonSpikeAutoAimComponent;
		AimComp.StartAiming(Player, Settings);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UPlayerAimingSettings::ClearScreenSpaceAimOffset(Player, this);
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