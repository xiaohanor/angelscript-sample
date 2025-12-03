class UBattlefieldHoverboardTrickComboPointsWidgetCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(BattlefieldHoverboardCapabilityTags::Hoverboard);
	default CapabilityTags.Add(BattlefieldHoverboardCapabilityTags::HoverboardTrick);
	default CapabilityTags.Add(BattlefieldHoverboardCapabilityTags::HoverboardTrickScore);

	default TickGroup = EHazeTickGroup::Gameplay;

	UBattlefieldHoverboardTrickComponent TrickComp;
	UBattlefieldHoverboardTrickSettings Settings;
	UBattlefieldHoverboardTrickComboPointsWidget Widget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TrickComp = UBattlefieldHoverboardTrickComponent::Get(Player);
		Settings = UBattlefieldHoverboardTrickSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!TrickComp.CurrentTrickCombo.IsSet())
			return false;

		if(TrickComp.CurrentTrickCombo.Value.ComboPoints <= 0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(TrickComp.CurrentTrickCombo.IsSet() && !TrickComp.bTrickFailed)
			return false;
		
		// const float TimeSinceComboEnded = Time::GetGameTimeSince(TrickComp.LastTimeTrickComboCompleted); 
		// if(TimeSinceComboEnded <= Settings.ComboPointFadeDelay + Settings.ComboPointFadeDuration)
		// 	return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Widget = Player.AddWidget(Settings.ComboPointWidgetClass);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(Widget != nullptr)
		{
			//Player.RemoveWidget(Widget);
			Widget = nullptr;
		}
	}
};