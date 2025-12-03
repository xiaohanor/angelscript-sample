UCLASS(Abstract)
class UScifiCopsGunHeatWidget : UHazeUserWidget
{
	float CurentHeat = 0;
	float HeatAlpha = 0;
	float OverHeatAlpha = 0;

	UPROPERTY(BindWidget)
	UScaleBox WidgetScale;

	UPROPERTY(BindWidget)
	URadialProgressWidget HeatWidget;

	UFUNCTION(BlueprintOverride)
	void OnAdded()
	{
		HeatWidget.BarStartAngle = 0;
		HeatWidget.BarEndAngle = 1;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		HeatWidget.SetProgress(CurentHeat);

		if(OverHeatAlpha > 0)
		{
			WidgetScale.UserSpecifiedScale = (OverHeatAlpha * 0.8) + (OverHeatAlpha * Math::Sin(Time::GetRealTimeSeconds() * 10) * 0.3);
			HeatWidget.ColorAndOpacity = FLinearColor(1, 0, 0, 0.4);
		}
		else
		{
			WidgetScale.UserSpecifiedScale = 1;
			HeatWidget.ColorAndOpacity = FLinearColor(1, 1, 1, 0.3);
		}
	}
}