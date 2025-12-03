class ULightBirdCrosshairWidget : UCrosshairWidget
{
	ULightBirdUserComponent UserComp;

	UPROPERTY(Meta = (BindWidget))
	UWidget Widget;

	UPROPERTY(Meta = (BindWidget))
	UWidget IndicatorWidget;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		UserComp = ULightBirdUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		auto WidgetVisibility = ESlateVisibility::Visible;
		auto IndicatorVisibility = ESlateVisibility::Collapsed;
		if (UserComp.AimTargetData.IsValid())
		{
			WidgetVisibility = ESlateVisibility::Collapsed;
			IndicatorVisibility = ESlateVisibility::Visible;
		}

//		Widget.Visibility = WidgetVisibility;
		IndicatorWidget.Visibility = IndicatorVisibility;
	}
}