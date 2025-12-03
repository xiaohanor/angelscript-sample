class UAdultDragonAcidProjectileAimCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragon);
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragonAim);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 18;

	default DebugCategory = SummitDebugCapabilityTags::AdultDragon;

	UPlayerAimingComponent AimComp;
	UPlayerAcidAdultDragonComponent DragonComp;
	UPlayerTargetablesComponent PlayerTargetables;

	bool bAimingWithCrosshair = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AimComp = UPlayerAimingComponent::Get(Player);
		DragonComp = UPlayerAcidAdultDragonComponent::Get(Player);
		PlayerTargetables = UPlayerTargetablesComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!DragonComp.WantsAiming())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!DragonComp.WantsAiming())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// JOHN - experimenting a little with moving the aim slightly down
		UPlayerAimingSettings::SetScreenSpaceAimOffset(Player, FVector2D(FVector2D(0.0, 0.01)), this, EHazeSettingsPriority::Gameplay);
		AimWithoutCrosshair();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UPlayerAimingSettings::ClearScreenSpaceAimOffset(Player, this);
		AimComp.StopAiming(Player);
	}

	void AimWithCrosshair()
	{
		FAimingSettings Settings;
		Settings.bShowCrosshair = true;
		Settings.bUseAutoAim = true;
		Settings.bApplyAimingSensitivity = false;
		Settings.OverrideCrosshairWidget = DragonComp.AcidShotCrosshair;
		Settings.OverrideAutoAimTarget = UAdultDragonAcidAutoAimComponent;
		AimComp.StartAiming(Player, Settings);
		bAimingWithCrosshair = true;
	}

	void AimWithoutCrosshair()
	{
		FAimingSettings Settings;
		Settings.bShowCrosshair = false;
		Settings.bUseAutoAim = true;
		Settings.bApplyAimingSensitivity = false;
		Settings.OverrideCrosshairWidget = DragonComp.AcidShotCrosshair;
		Settings.OverrideAutoAimTarget = UAdultDragonAcidAutoAimComponent;
		AimComp.StartAiming(Player, Settings);
		bAimingWithCrosshair = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto AimResult = AimComp.GetAimingTarget(Player);
		FVector AimDirection = AimResult.AimDirection;

		// Debug::DrawDebugDirectionArrow(AimResult.AimOrigin, AimDirection, 5000, 40, FLinearColor::Red, 20);
		DragonComp.AimDirection = AimDirection;
		DragonComp.AimOrigin = AimResult.AimOrigin;

		if (AimComp.GetAimingTarget(Player).AutoAimTarget != nullptr && !bAimingWithCrosshair)
		{
			AimComp.StopAiming(Player);
			AimWithCrosshair();
		}
		else if (AimComp.GetAimingTarget(Player).AutoAimTarget == nullptr && bAimingWithCrosshair)
		{
			AimComp.StopAiming(Player);
			AimWithoutCrosshair();
		}
	}
};