UCLASS(Abstract)
class USkylinePhoneScreenWidget : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UOverlay CursorOverlay;

	UPROPERTY(BindWidget)
	USkylinePhoneTimerWidget Timer;

	UCanvasPanelSlot CursorSlot;

	private FVector2D CursorPosition;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		CursorSlot = Cast<UCanvasPanelSlot>(CursorOverlay.Slot);
	}

	void SetCursorPosition(FVector2D NewPosition)
	{
		if(CursorSlot == nullptr)
			return;

		CursorSlot.Position = NewPosition;
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnClick()
	{
	}
}