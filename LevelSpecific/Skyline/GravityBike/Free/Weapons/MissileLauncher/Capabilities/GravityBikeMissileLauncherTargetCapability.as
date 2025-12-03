class UGravityBikeMissileLauncherTargetCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(n"GravityBikeFreeWeaponTargeting");

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 80;

	UGravityBikeFreeDriverComponent DriverComp;
	UGravityBikeMissileLauncherComponent MissileLauncherComp;
	UPlayerAimingComponent AimComp;
	UPlayerTargetablesComponent TargetablesComp;
	UGravityBikeWeaponUserComponent WeaponComp;

	UCrosshairWidget CrosshairWidget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DriverComp = UGravityBikeFreeDriverComponent::Get(Player);
		MissileLauncherComp = UGravityBikeMissileLauncherComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);
		WeaponComp = UGravityBikeWeaponUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!MissileLauncherComp.IsEquipped())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!MissileLauncherComp.IsEquipped())
			return true;

		return false;	
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ApplySettings(MissileLauncherComp.PlayerAimingSettings, this);

		FAimingSettings AimingSettings;
		AimingSettings.bShowCrosshair = false;
		AimingSettings.bApplyAimingSensitivity = false;
		AimingSettings.OverrideCrosshairWidget = WeaponComp.CrosshairWidget;
		AimingSettings.bUseAutoAim = true;
		AimingSettings.bCrosshairFollowsTarget = false;
		AimingSettings.OverrideAutoAimTarget = UGravityBikeWeaponTargetableComponent;
		AimComp.StartAiming(MissileLauncherComp, AimingSettings);

		AGravityBikeFree GravityBike = DriverComp.GetGravityBike();
		auto GravityBikeCrosshairWidget = Cast<UGravityBikeFreeCrosshairWidget>(GravityBike.CrosshairWidgetComp.GetUserWidgetObject());
		if(GravityBikeCrosshairWidget != nullptr)
		{
			GravityBikeCrosshairWidget.Initialize(Player);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimComp.ClearAimingRayOverride(this);
		AimComp.StopAiming(MissileLauncherComp);

		Player.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
//		PrintToScreen("AccSteering: " + DriverComp.GetGravityBike().AccSteering.Value, 0.0, FLinearColor::Green);

		FAimingRay OverrideAimingRay;
		OverrideAimingRay.Origin = Player.ActorCenterLocation;
		OverrideAimingRay.Direction = Player.ActorForwardVector;
//		AimComp.ApplyAimingRayOverride(OverrideAimingRay, this);

		auto AimingRay = AimComp.GetPlayerAimingRay();

		auto AimingResult = AimComp.GetAimingTarget(MissileLauncherComp);

		MissileLauncherComp.AimTarget = FGravityBikeWeaponTargetData();
	
		if (AimingResult.AutoAimTarget != nullptr)
		{
			MissileLauncherComp.AimTarget = FGravityBikeWeaponTargetData(AimingResult.AutoAimTarget, AimingResult.AutoAimTargetPoint);

			// Always show the widget
			FTargetableWidgetSettings WidgetSettings;
			WidgetSettings.TargetableCategory = GetTargetableCategory();
			WidgetSettings.DefaultWidget = MissileLauncherComp.TargetWidgetClass;
			WidgetSettings.MaximumVisibleWidgets = 1;
			WidgetSettings.bOnlyShowWidgetsForPossibleTargets = true;
			TargetablesComp.ShowWidgetsForTargetables(WidgetSettings);

			// Only show outline if we can fire
			if (WeaponComp.HasChargeFor(MissileLauncherComp.MissileLauncher.GetChargePerShot()))
			{
				FTargetableOutlineSettings OutlineSettings;
				OutlineSettings.TargetableCategory = GetTargetableCategory();
				OutlineSettings.bOnlyShowOneTarget = true;
				TargetablesComp.ShowOutlinesForTargetables(OutlineSettings);
			}
		}

		WeaponComp.bCanFireAtTarget = (AimingResult.AutoAimTarget != nullptr && WeaponComp.HasChargeFor(MissileLauncherComp.MissileLauncher.GetChargePerShot()));

		if (!MissileLauncherComp.AimTarget.IsHoming())
		{
			/*
			FVector Origin = Player.ActorCenterLocation;
			FVector Direction = Player.ActorForwardVector;

			auto Trace = Trace::InitChannel(ECollisionChannel::PlayerAiming);
			Trace.IgnorePlayers();
			Trace.IgnoreActor(DriverComp.GetGravityBike());
//			auto HitResult = Trace.QueryTraceSingle(AimingRay.Origin, AimingRay.Origin + AimingRay.Direction * 500000.0);
			auto HitResult = Trace.QueryTraceSingle(Origin, Origin + Direction * 500000.0);

			FVector EndLocation = HitResult.TraceEnd;

			if (HitResult.bBlockingHit)
			{
				EndLocation = HitResult.ImpactPoint;
				MissileLauncherComp.AimTarget = FGravityBikeWeaponTargetData(
					HitResult.Component,
					EndLocation
				);
			}
			else
			{
				MissileLauncherComp.AimTarget = FGravityBikeWeaponTargetData(EndLocation);
			}
			*/
		}
	}

	FName GetTargetableCategory() const
	{
		return Cast<UGravityBikeWeaponTargetableComponent>(UGravityBikeWeaponTargetableComponent.DefaultObject).TargetableCategory;
	}
}