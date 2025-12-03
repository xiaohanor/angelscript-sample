UCLASS(Abstract)
class AMaxSecurityLaserCutterCrosshair : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent CrosshairRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ProgressRoot;

	UPROPERTY(DefaultComponent, Attach = ProgressRoot)
	UWidgetComponent RadialProgressComp;
	default RadialProgressComp.bHiddenInGame = true;

	URadialProgressWidget RadialProgressWidget;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RadialProgressWidget = Cast<URadialProgressWidget>(RadialProgressComp.Widget);
		RadialProgressWidget.CircleColor = FLinearColor(0.82, 0.00, 0.00);
		RadialProgressWidget.RadiusMinimum = 0.55;
	}

	void ShowProgressBar()
	{
		RadialProgressComp.SetHiddenInGame(false);
	}

	void HideProgressBar()
	{
		RadialProgressComp.SetHiddenInGame(true);
	}

	void SetChargeProgress(float Alpha)
	{
		RadialProgressWidget.SetProgress(Alpha);
	}
}