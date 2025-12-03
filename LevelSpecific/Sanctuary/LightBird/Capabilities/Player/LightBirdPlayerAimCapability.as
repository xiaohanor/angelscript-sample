class ULightBirdPlayerAimCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(LightBird::Tags::LightBird);
	default CapabilityTags.Add(LightBird::Tags::LightBirdAim);

	default CapabilityTags.Add(BlockedWhileIn::Crouch);
	default CapabilityTags.Add(BlockedWhileIn::Grapple);
	default CapabilityTags.Add(BlockedWhileIn::Ladder);
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ULightBirdUserComponent UserComp;
	UPlayerAimingComponent AimComp;
	UPlayerTargetablesComponent TargetablesComp;
	float LastActivationTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = ULightBirdUserComponent::Get(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
		TargetablesComp = UPlayerTargetablesComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		float TimeSinceActivation = Time::GetRealTimeSince(LastActivationTime);
		if (TimeSinceActivation > 0.33 || LastActivationTime == 0.0)
		{
			if (IsActioning(ActionNames::PrimaryLevelAbility))
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (WasActionStarted(ActionNames::Cancel))
			return true;

		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LastActivationTime = Time::RealTimeSeconds;

		FAimingSettings AimSettings;
		AimSettings.bShowCrosshair = !SceneView::IsFullScreen();
		AimSettings.bUseAutoAim = true;
		AimSettings.bApplyAimingSensitivity = true;
		AimSettings.OverrideAutoAimTarget = ULightBirdTargetComponent;
		AimSettings.OverrideCrosshairWidget = UserComp.CrosshairWidgetClass;
		AimSettings.bCrosshairFollowsTarget = true;
		AimComp.StartAiming(UserComp, AimSettings);

		UserComp.Aim();

		if (UserComp.CameraAimSettings != nullptr)
			Player.ApplyCameraSettings(UserComp.CameraAimSettings, 0.8, this, EHazeCameraPriority::Low);

		UserComp.LastAimStartTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimComp.StopAiming(UserComp);

		if (UserComp.State == ELightBirdState::Aiming)
			UserComp.Hover();

		Player.ClearCameraSettingsByInstigator(this, 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto AimingTarget = AimComp.GetAimingTarget(UserComp);

		FLightBirdTargetData TargetData;
		if (TargetablesComp.TargetingMode.Get() == EPlayerTargetingMode::ThirdPerson)
		{
			if (AimingTarget.AutoAimTarget != nullptr)
			{
				TargetData = FLightBirdTargetData(
					AimingTarget.AutoAimTarget,
					NAME_None,
					AimingTarget.AutoAimTargetPoint,
					false);
			}
			else
			{
				auto AimingRay = AimingTarget.Ray;
				TargetData = UserComp.GetTargetDataFromTrace(AimingRay.Origin, AimingRay.Origin + AimingRay.Direction * LightBird::Aim::Range, LightBird::Aim::bCanAttachToSurfaces);
			}
		}
		else
		{
			if (AimingTarget.AutoAimTarget != nullptr)
			{
				TargetData = FLightBirdTargetData(
					AimingTarget.AutoAimTarget,
					NAME_None,
					AimingTarget.AutoAimTargetPoint,
					false);
			}
		}

		UserComp.AimTargetData = TargetData;

		FTargetableOutlineSettings OutlineSettings;
		OutlineSettings.TargetableCategory = n"LightBird";
		OutlineSettings.bOnlyShowOneTarget = true;
		TargetablesComp.ShowOutlinesForTargetables(OutlineSettings);

		if (SceneView::IsFullScreen())
		{
			TargetablesComp.ShowWidgetsForTargetables(n"LightBird", UserComp.FullscreenTargetableWidget);
		}
	}
}