class USkylineTorHammerAimPlayerCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 90;

	UGravityWhipUserComponent UserComp;
	UPlayerAimingComponent AimComp;
	UPlayerTargetablesComponent PlayerTargetablesComp;
	USkylineTorHammerStolenPlayerComponent StolenComp;
	bool bInitiated;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StolenComp = USkylineTorHammerStolenPlayerComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (AimComp != nullptr)
			return;
		AimComp = UPlayerAimingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!StolenComp.bStolen)
			return false;
		if (AimComp == nullptr)
			return false;
		if (AimComp.IsAiming(StolenComp))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!StolenComp.bStolen)
			return true;
		return false;	
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UserComp = UGravityWhipUserComponent::Get(Owner);
		PlayerTargetablesComp = UPlayerTargetablesComponent::Get(Owner);

		FAimingSettings AimSettings;
		AimSettings.bUseAutoAim = true;
		AimSettings.bCrosshairFollowsTarget = false;
		AimSettings.bShowCrosshair = GravityWhip::Common::bShowCrosshair;
		AimSettings.bApplyAimingSensitivity = true;
		AimSettings.OverrideAutoAimTarget = USkylineTorHammerStolenAutoAimComponent;
		AimSettings.OverrideCrosshairWidget = UserComp.CrosshairWidget;
		AimComp.StartAiming(n"TorHammerAim", AimSettings);
		Player.EnableStrafe(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimComp.StopAiming(n"TorHammerAim");
		Player.DisableStrafe(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FTargetableWidgetSettings WidgetSettings;
		WidgetSettings.TargetableCategory = GravityWhip::Grab::SlingTargetableCategory;
		WidgetSettings.DefaultWidget = UserComp.TargetWidgetClass;
		WidgetSettings.MaximumVisibleWidgets = 1;
		WidgetSettings.bOnlyShowWidgetsForPossibleTargets = true;
		PlayerTargetablesComp.ShowWidgetsForTargetables(WidgetSettings);

		FTargetableOutlineSettings OutlineSettings;
		OutlineSettings.TargetableCategory = GravityWhip::Grab::SlingTargetableCategory;
		OutlineSettings.bOnlyShowOneTarget = true;
		PlayerTargetablesComp.ShowOutlinesForTargetables(OutlineSettings);
	}
}