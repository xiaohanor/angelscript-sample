class UGravityWhipSlingAimCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(GravityWhipTags::GravityWhip);
	default CapabilityTags.Add(GravityWhipTags::GravityWhipAim);
	default CapabilityTags.Add(GravityWhipTags::GravityWhipGameplay);

	default DebugCategory = GravityWhipTags::GravityWhip;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 90;

	UGravityWhipUserComponent UserComp;
	UPlayerAimingComponent AimComp;
	UPlayerTargetablesComponent PlayerTargetablesComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UGravityWhipUserComponent::Get(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
		PlayerTargetablesComp = UPlayerTargetablesComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!UserComp.HasActiveGrab())
			return false;

		if (UserComp.GetPrimaryGrabMode() != EGravityWhipGrabMode::Sling)
			return false;


		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!UserComp.IsGrabbingAny())
			return true;

		if (UserComp.GetPrimaryGrabMode() != EGravityWhipGrabMode::Sling)
			return true;

		return false;	
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FAimingSettings AimSettings;
		AimSettings.bUseAutoAim = true;
		AimSettings.bCrosshairFollowsTarget = false;
		AimSettings.bShowCrosshair = GravityWhip::Common::bShowCrosshair;
		AimSettings.bApplyAimingSensitivity = true;
		AimSettings.OverrideAutoAimTarget = UGravityWhipSlingAutoAimComponent;
		AimSettings.OverrideCrosshairWidget = UserComp.CrosshairWidget;
		AimComp.StartAiming(UserComp, AimSettings);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimComp.StopAiming(UserComp);
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