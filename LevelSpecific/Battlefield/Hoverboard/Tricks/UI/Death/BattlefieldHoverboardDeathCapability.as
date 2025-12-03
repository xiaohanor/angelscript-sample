class UBattlefieldHoverboardDeathCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(BattlefieldHoverboardCapabilityTags::Hoverboard);
	default CapabilityTags.Add(BattlefieldHoverboardCapabilityTags::HoverboardTrick);
	default CapabilityTags.Add(BattlefieldHoverboardCapabilityTags::HoverboardTrickScore);

	default DebugCategory = n"Hoverboard";

	UBattlefieldHoverboardTrickSettings TrickSettings;
	UBattlefieldHoverboardTrickComponent TrickComp;
	UBattleFieldHoverboardPointsLostWidget Widget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TrickComp = UBattlefieldHoverboardTrickComponent::Get(Player);
		TrickSettings = UBattlefieldHoverboardTrickSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Player.IsPlayerDead())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Player.IsPlayerDead())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TrickComp.RemoveTrickPoints(TrickSettings.PointLossOnDeath);
		Widget = Player.AddWidget(TrickSettings.PointsLostWidget);
		Widget.LostPointsText.SetText(FText::FromString(f"-{TrickSettings.PointLossOnDeath}"));
		TrickComp.CurrentTrickCombo.Reset();
		TrickComp.CurrentTrick.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(Widget != nullptr)
		{
			Player.RemoveWidget(Widget);
			Widget = nullptr;
		}
	}
};