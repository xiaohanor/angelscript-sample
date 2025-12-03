class USkylineInnerCityTelevatorWidget : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UTextBlock TextBlock;

	void SetText(FText DisplayText)
	{
		TextBlock.SetText(DisplayText);
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnFloorReached(bool bRoof){}

	UFUNCTION(BlueprintEvent)
	void BP_OnStartMoving(){}
}