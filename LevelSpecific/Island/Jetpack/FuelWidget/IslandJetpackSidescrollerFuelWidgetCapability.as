class UIslandJetpackSidescrollerFuelWidgetCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	default DebugCategory = IslandJetpack::Jetpack;

	UIslandJetpackComponent JetpackComp;
	UIslandSidescrollerComponent SidescrollerComp;

	UIslandJetpackSettings JetpackSettings;

	TPerPlayer<UIslandJetpackSidescrollerFuelWidget> FuelWidget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JetpackComp = UIslandJetpackComponent::Get(Player);
		SidescrollerComp = UIslandSidescrollerComponent::Get(Player);

		JetpackSettings = UIslandJetpackSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!JetpackComp.IsOn())
			return false;

		if(SidescrollerComp == nullptr)
			return false;

		if(!SidescrollerComp.IsInSidescrollerMode())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!JetpackComp.IsOn())
			return true;

		if(SidescrollerComp == nullptr)
			return true;

		if(!SidescrollerComp.IsInSidescrollerMode())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for(auto JetpackingPlayer : Game::Players)
		{
			if(FuelWidget[JetpackingPlayer] == nullptr)
			{
				FuelWidget[JetpackingPlayer] = JetpackingPlayer.AddWidget(JetpackSettings.SidescrollerFuelWidgetClass);
				FuelWidget[JetpackingPlayer].ActualPlayerOwner = Player;
				FuelWidget[JetpackingPlayer].JetpackSettings = JetpackSettings;
				FuelWidget[JetpackingPlayer].AttachWidgetToComponent(Player.Mesh, n"Head");
			}
			FuelWidget[JetpackingPlayer].bFuelWidgetVisible = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for(auto JetpackingPlayer : Game::Players)
		{
			FuelWidget[JetpackingPlayer].bFuelWidgetVisible = false;
			FuelWidget[JetpackingPlayer].bHasRunOutOfFuel = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for(auto JetpackingPlayer : Game::Players)
		{
			FuelWidget[JetpackingPlayer].FuelAlpha = JetpackComp.GetChargeLevel();
			FuelWidget[JetpackingPlayer].bHasRunOutOfFuel = JetpackComp.HasEmptyCharge();
			FuelWidget[JetpackingPlayer].bJetpackIsActive = JetpackComp.bThrusterIsOn;
			FuelWidget[JetpackingPlayer].bIsBoosting = JetpackComp.bBoosting;
		}
	}
};