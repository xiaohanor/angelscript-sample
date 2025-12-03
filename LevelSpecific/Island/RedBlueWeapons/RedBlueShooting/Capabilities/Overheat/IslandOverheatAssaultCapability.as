class UIslandRedBlueOverheatAssaultCapability : UHazePlayerCapability
{
	UIslandRedBlueWeaponUserComponent WeaponUserComponent;
	UIslandRedBlueOverheatAssaultUserComponent OverheatUserComponent;
	UPlayerAimingComponent AimComp;

	UIslandRedBlueAimCrosshairWidget Crosshair;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WeaponUserComponent = UIslandRedBlueWeaponUserComponent::Get(Player);
		OverheatUserComponent = UIslandRedBlueOverheatAssaultUserComponent::GetOrCreate(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(WeaponUserComponent.CurrentUpgradeType != EIslandRedBlueWeaponUpgradeType::OverheatAssault)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(WeaponUserComponent.CurrentUpgradeType != EIslandRedBlueWeaponUpgradeType::OverheatAssault)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Add any model attachments here
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Remove any model attachments here

		if(Crosshair != nullptr)
		{
			Crosshair.bOverheatBarVisible = false;
			Crosshair.OverheatAlpha = 0.0;
			Crosshair.bIsOverheated = false;
		}
		WeaponUserComponent.WeaponAnimData.bIsOverheated = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Crosshair = Cast<UIslandRedBlueAimCrosshairWidget>(AimComp.GetCrosshairWidget(WeaponUserComponent));

		if(Crosshair != nullptr)
		{
			Crosshair.OverheatAlpha = OverheatUserComponent.OverheatAlpha;
			Crosshair.bIsOverheated = OverheatUserComponent.bIsOverheated;
			Crosshair.bOverheatBarVisible = true;
		}

		WeaponUserComponent.WeaponAnimData.bIsOverheated = OverheatUserComponent.bIsOverheated;
	}
}