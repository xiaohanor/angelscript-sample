UCLASS(Abstract)
class UBattlefieldHoverboardTrickComboHistoryWidget : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	URetainerBox RetainerBox;

	UPROPERTY(BindWidget)
	UVerticalBox VerticalBox;

	UPROPERTY()
	TSubclassOf<UBattleFieldHoverboardTrickTextWidget> TrickTextWidgetClass;

	UBattlefieldHoverboardTrickComponent TrickComp;
	UBattlefieldHoverboardTrickSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		TrickComp = UBattlefieldHoverboardTrickComponent::Get(Player);
		Settings = UBattlefieldHoverboardTrickSettings::GetSettings(Player);
		TrickComp.OnNewTrick.AddUFunction(this, n"OnNewTrick");
		OnNewTrick(TrickComp.CurrentTrick.Value.Type);

		// if(Player.IsZoe())
		// {
		// 	auto CanvasPanelSlot = Cast<UCanvasPanelSlot>(RetainerBox.Slot);
		// 	CanvasPanelSlot.SetAnchors(FAnchors(0.0, 1.0));
		// 	CanvasPanelSlot.SetAlignment(FVector2D(0.0, 1.0));
		// 	auto Offsets = CanvasPanelSlot.Offsets;
		// 	Offsets.Left *= -1;
		// 	CanvasPanelSlot.SetOffsets(Offsets);
		// }
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if(TrickComp.CurrentTrickCombo.IsSet())
		{
			auto CurrentCombo = TrickComp.CurrentTrickCombo.Value;

			// float CurrentOpacity = ScoreText.GetRenderOpacity();
			// if(CurrentOpacity < 1.0)
			// 	ScoreText.SetOpacity(Math::FInterpConstantTo(CurrentOpacity, 1, InDeltaTime, 1 / Settings.ComboPointFadeDuration));
		}
		// Combo has ended, make text fade out
		else
		{
			// const float TimeSinceComboEnded = Time::GetGameTimeSince(TrickComp.LastTimeTrickComboCompleted);
			// if(TimeSinceComboEnded > Settings.ComboPointFadeDelay)
			// 	ScoreText.SetOpacity(Math::FInterpConstantTo(ScoreText.GetRenderOpacity(), 0, InDeltaTime, 1 / Settings.ComboPointFadeDuration));
		}		
	}

	UFUNCTION()
	private void OnNewTrick(EBattlefieldHoverboardTrickType Trick)
	{
		UBattleFieldHoverboardTrickTextWidget TextWidget = Widget::CreateUserWidget(Player, TrickTextWidgetClass);
		
		TextWidget.TrickText.DynamicFontMaterial.SetVectorParameterValue(n"BottomColor", Player.GetPlayerUIColor());
		TextWidget.TrickText.DynamicFontMaterial.SetVectorParameterValue(n"TopColor", Settings.Color2[Player]);

		TextWidget.TrickText.SetText(Settings.TrickNames[Trick]);
		VerticalBox.AddChildAt(TextWidget, 0);
		if(VerticalBox.ChildrenCount >= 5)
		{
			VerticalBox.RemoveChild(VerticalBox.AllChildren.Last());
		}
	}
}