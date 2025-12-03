class UAccessibilityOptionsMenuPage : UOptionsMenuPage
{
	// UPROPERTY(BindWidget)
	// UOptionEnumWidget MenuNarration;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		Super::Construct();
	}

	// UFUNCTION(BlueprintOverride)
	// void Tick(FGeometry MyGeometry, float InDeltaTime)
	// {
	// 	EHazeAccessibilityState NarrationState = Online::GetAccessibilityState(EHazeAccessibilityFeature::MenuNarration);
	// 	if (NarrationState == EHazeAccessibilityState::GameTurnedOn || NarrationState == EHazeAccessibilityState::GameTurnedOff)
	// 	{
	// 		MenuNarration.Visibility = ESlateVisibility::Visible;
	// 	}
	// 	else
	// 	{
	// 		MenuNarration.Visibility = ESlateVisibility::Collapsed;
	// 	}
	// }
}