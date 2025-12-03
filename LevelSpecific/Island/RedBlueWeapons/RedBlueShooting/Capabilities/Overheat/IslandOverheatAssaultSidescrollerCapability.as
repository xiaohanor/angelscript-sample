class UIslandRedBlueOverheatAssaultSidescrollerCapability : UHazePlayerCapability
{
	UIslandRedBlueWeaponUserComponent WeaponUserComponent;
	UIslandRedBlueOverheatAssaultUserComponent OverheatUserComponent;
	UPlayerAimingComponent AimComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	UIslandRedBlueOverheat2DWidget Overheat2DWidget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WeaponUserComponent = UIslandRedBlueWeaponUserComponent::Get(Player);
		OverheatUserComponent = UIslandRedBlueOverheatAssaultUserComponent::GetOrCreate(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(WeaponUserComponent.CurrentUpgradeType != EIslandRedBlueWeaponUpgradeType::OverheatAssault)
			return false;

		if(PerspectiveModeComp.PerspectiveMode != EPlayerMovementPerspectiveMode::SideScroller && !WeaponUserComponent.Is2DOverheatWidgetForced())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(WeaponUserComponent.CurrentUpgradeType != EIslandRedBlueWeaponUpgradeType::OverheatAssault)
			return true;

		if(PerspectiveModeComp.PerspectiveMode != EPlayerMovementPerspectiveMode::SideScroller && !WeaponUserComponent.Is2DOverheatWidgetForced())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(Overheat2DWidget == nullptr)
		{
			Overheat2DWidget = Game::Mio.AddWidget(WeaponUserComponent.Overheat2DWidget);
			Overheat2DWidget.ActualPlayerOwner = Player;
		}

		Overheat2DWidget.bOverheatBarVisible = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Overheat2DWidget.bOverheatBarVisible = false;
		Overheat2DWidget.OverheatAlpha = 0.0;
		Overheat2DWidget.bIsOverheated = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Overheat2DWidget.OverheatAlpha = OverheatUserComponent.OverheatAlpha;
		Overheat2DWidget.bIsOverheated = OverheatUserComponent.bIsOverheated;
	}
}