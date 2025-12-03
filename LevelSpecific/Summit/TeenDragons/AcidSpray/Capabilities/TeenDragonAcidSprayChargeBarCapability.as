class UTeenDragonAcidSprayChargeBarCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonAcidSpray);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	UPlayerAcidTeenDragonComponent DragonComp;
	UTeenDragonAcidSprayComponent SprayComp;

	UTeenDragonStaminaWidget Widget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerAcidTeenDragonComponent::Get(Player);
		SprayComp = UTeenDragonAcidSprayComponent::Get(Player);

		Widget = Player.AddWidget(DragonComp.StaminaWidget);
		Player.RemoveWidget(Widget);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Show the stamina widget or not
		bool bShouldShowStamina = SprayComp.RemainingAcidAlpha < 1.0;
		if (bShouldShowStamina && !Widget.bIsAdded)
		{
			Player.AddExistingWidget(Widget);
			Widget.AttachWidgetToComponent(Player.RootComponent);
			Widget.SetWidgetRelativeAttachOffset(DragonComp.StaminaWidgetWorldOffset);
		}
		else if (!bShouldShowStamina && Widget.bIsAdded)
		{
			Player.RemoveWidget(Widget);
		}

		// Update the stamina in the widget
		if (Widget.bIsAdded)
		{
			Widget.CurentStamina = SprayComp.RemainingAcidAlpha;
			Widget.StaminaBar.SetProgress(Widget.CurentStamina);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (Widget.bIsAdded)
			Player.RemoveWidget(Widget);
	}
};