class UWandAimCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UPlayerAimingComponent AimComp;
	UWandPlayerComponent UserComp;

	FRotator WandOriginalRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UWandPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (UserComp.PlayerData.Player == nullptr)
			return false;

		if(UserComp.PlayerData.bIsCasting)
			return false;

		if(DeactiveDuration < 1)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (UserComp.PlayerData.Player == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UserComp.TargetActor = nullptr;
		AimComp = UPlayerAimingComponent::Get(Player);

		FAimingSettings AimSettings;
		AimSettings.bApplyAimingSensitivity = false;
		AimSettings.bShowCrosshair = true;
		AimSettings.OverrideCrosshairWidget = UserComp.CrosshairClass;
		AimSettings.bUseAutoAim = true;
		AimSettings.bCrosshairFollowsTarget = true;
		AimSettings.OverrideAutoAimTarget = UserComp.PlayerData.AutoAimClass;
		AimComp.StartAiming(UserComp, AimSettings);

		UserComp.Crosshair = Cast<UMoonMarketWandCrosshair>(AimComp.GetCrosshairWidget(UserComp));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimComp.StopAiming(UserComp);
		UserComp.Crosshair = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};