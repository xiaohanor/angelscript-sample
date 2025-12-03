class UAdultDragonTailSmashModeWidget : UHazeUserWidget
{
	UPROPERTY()
	float CurrentStaminaAlpha = 0.0;

	UPROPERTY(BindWidget)
	URadialProgressWidget StaminaBar;
}