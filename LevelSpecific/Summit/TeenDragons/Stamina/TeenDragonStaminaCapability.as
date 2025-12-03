
class UTeenDragonStaminaCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	//ATeenDragon TeenDragon;
	//AHazePlayerCharacter Player;
	UPlayerTeenDragonComponent DragonComp;

	UTeenDragonStaminaWidget Widget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		//TeenDragon = Cast<ATeenDragon>(Owner);
		DragonComp = UPlayerTeenDragonComponent::Get(Player);
		//Player = TeenDragon.Player;

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
		// Regenerate stamina at the current rate
		DragonComp.CurrentStamina += DeltaTime * DragonComp.GetCurrentStaminaRegenerationRate();
		DragonComp.CurrentStamina = Math::Clamp(DragonComp.CurrentStamina, 0.0, 1.0);

		// Show the stamina widget or not
		bool bShouldShowStamina = DragonComp.CurrentStamina < 1.0;
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
			Widget.CurentStamina = DragonComp.CurrentStamina;
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

class UTeenDragonStaminaWidget : UHazeUserWidget
{
	UPROPERTY()
	float CurentStamina = 0.0;

	UPROPERTY(BindWidget)
	URadialProgressWidget StaminaBar;
};