class UBattlefieldHoverboardTrickTotalPointsWidgetCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(BattlefieldHoverboardCapabilityTags::Hoverboard);
	default CapabilityTags.Add(BattlefieldHoverboardCapabilityTags::HoverboardTotalScore);
	default CapabilityTags.Add(BattlefieldHoverboardCapabilityTags::HoverboardTrickScore);

	default TickGroup = EHazeTickGroup::Gameplay;

	UBattlefieldHoverboardTrickSettings Settings;

	UBattlefieldHoverboardTrickTotalPointsWidget Widget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = UBattlefieldHoverboardTrickSettings::GetSettings(Player);
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
		Widget = Player.AddWidget(Settings.TotalPointWidgetClass);
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