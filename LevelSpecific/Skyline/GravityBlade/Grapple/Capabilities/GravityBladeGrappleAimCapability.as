class UGravityBladeGrappleAimCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(GravityBladeTags::GravityBlade);
	default CapabilityTags.Add(GravityBladeTags::GravityBladeWield);
	default CapabilityTags.Add(GravityBladeTags::GravityBladeAim);

	default CapabilityTags.Add(GravityBladeGrappleTags::GravityBladeGrapple);
	default CapabilityTags.Add(GravityBladeGrappleTags::GravityBladeGrappleAim);

	default CapabilityTags.Add(BlockedWhileIn::Ladder);

	default DebugCategory = GravityBlade::DebugCategory;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 105;

	UGravityBladeGrappleUserComponent GrappleComp;

	UPlayerAimingComponent AimComp;
	UPlayerTargetablesComponent TargetablesComp;
	UPlayerTargetablesComponent PlayerTargetablesComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GrappleComp = UGravityBladeGrappleUserComponent::Get(Owner);
		
		AimComp = UPlayerAimingComponent::Get(Owner);
		TargetablesComp = UPlayerTargetablesComponent::Get(Owner);
		PlayerTargetablesComp = UPlayerTargetablesComponent::Get(Owner);
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
		// AimSettings.bShowCrosshair = GrappleComp.Settings.bShowCrosshair;
		AimSettings.bShowCrosshair = false;
		AimSettings.bApplyAimingSensitivity = GrappleComp.Settings.bApplyAimingSensitivity;
		AimSettings.bUseAutoAim = true;
		AimSettings.bCrosshairFollowsTarget = true;
		AimSettings.OverrideCrosshairWidget = GrappleComp.CrosshairWidgetClass;
		AimSettings.OverrideAutoAimTarget = UGravityBladeGrappleComponent;
		AimComp.StartAiming(GrappleComp, AimSettings);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimComp.StopAiming(GrappleComp);
		GrappleComp.AimGrappleData = FGravityBladeGrappleData();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(PlayerTargetablesComp.TargetingMode.Get() != EPlayerTargetingMode::SideScroller && GrappleComp.Settings.bUse2DTargeting)
		{
			PlayerTargetablesComp.TargetingMode.Apply(EPlayerTargetingMode::SideScroller, this, EInstigatePriority::High);
		}
		else if(PlayerTargetablesComp.TargetingMode.Get() == EPlayerTargetingMode::SideScroller && !GrappleComp.Settings.bUse2DTargeting)
		{
			PlayerTargetablesComp.TargetingMode.Clear(this);
			AimComp.ClearAimingRayOverride(this);
		}

		if(GrappleComp.Settings.bUse2DTargeting)
		{
			FAimingRay AimRay;
			AimRay.Origin = Player.ActorCenterLocation;
			AimRay.Direction = Player.ViewRotation.ForwardVector;
			AimComp.ApplyAimingRayOverride(AimRay, this);
		}

		GrappleComp.AimGrappleData = GrappleComp.QueryAimGrappleData();
		GrappleComp.TargetWidget = nullptr;

		// Show a widget on the thing we're going to be grappling to
		if (GrappleComp.AimGrappleData.IsValid())
		{
			auto TargetComp = UGravityBladeGrappleComponent::Get(GrappleComp.AimGrappleData.Actor);
			if (TargetComp != nullptr)
			{
				auto WidgetPool = UWidgetPoolComponent::GetOrCreate(Player);
				UTargetableWidget Widget = Cast<UTargetableWidget>(WidgetPool.TakeSingleFrameWidget(GrappleComp.GrappleWidgetClass, this));
				Widget.AttachWidgetToComponent(TargetComp);
				Widget.SetWidgetRelativeAttachOffset(TargetComp.CalculateWidgetVisualOffset(Player, Widget));
				Widget.bIsPrimaryTarget = true;
				Widget.UsableByPlayers = EHazeSelectPlayer::Mio;

				Widget.SetWidgetShowInFullscreen(true);
				Widget.OnUpdated();
				Widget.bAttachToEdgeOfScreen = false;
				GrappleComp.TargetWidget = Cast<UGravityBladeGrappleTargetWidget>(Widget);
			}
		}
	}
}