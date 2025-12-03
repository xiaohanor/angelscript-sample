class UAdultDragonTailSmashModeChargeBarCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"AdultDragon");
	default CapabilityTags.Add(n"AdultDragonSmashMode");

	default DebugCategory = n"AdultDragon";

	UAdultDragonTailSmashModeComponent SmashComp;
	UAdultDragonTailSmashModeWidget Widget;
	UAdultDragonTailSmashModeSettings SmashModeSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SmashComp = UAdultDragonTailSmashModeComponent::Get(Player);

		SmashModeSettings = UAdultDragonTailSmashModeSettings::GetSettings(Player);

		//  NewWidget = Player.AddWidget(SmashModeSettings.ChargeBarWidget);
		UHazeUserWidget NewWidget = Widget::CreateUserWidget(Player, SmashModeSettings.ChargeBarWidget);
		Widget = Cast<UAdultDragonTailSmashModeWidget>(NewWidget);
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
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (Widget.bIsAdded)
			Player.RemoveWidget(Widget);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(SmashComp.SmashModeStamina < SmashModeSettings.SmashModeStaminaMax)
		{
			if(!Widget.bIsAdded)
			{
				Player.AddExistingWidget(Widget);
				Widget.AttachWidgetToComponent(Player.RootComponent);
				Widget.SetWidgetRelativeAttachOffset(SmashModeSettings.WidgetAttachOffset);				
			}

			float StaminaAlpha = SmashComp.SmashModeStamina / SmashModeSettings.SmashModeStaminaMax;
			Widget.CurrentStaminaAlpha = StaminaAlpha;
			Widget.StaminaBar.SetProgress(Widget.CurrentStaminaAlpha);
		}
		else
		{
			if(Widget.bIsAdded)
			{
				Player.RemoveWidget(Widget);
			}
		}
	}
}