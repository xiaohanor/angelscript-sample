class UMainMenuBusyTaskWidget : UMainMenuStateWidget
{
	default bShowMenuBackground = true;

	UPROPERTY(BindWidget)
	UHazeTextWidget BusyTaskTextWidget;

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		Super::Tick(MyGeometry, InDeltaTime);
		if (!bIsActive)
			return;

		if (BusyTaskTextWidget != nullptr && MainMenu != nullptr)
			BusyTaskTextWidget.SetText(MainMenu.GetBusyTaskText());
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry Geom, FKeyEvent Event)
	{
		if (MainMenu.IsOwnerInput(Event))
		{
			// Try to cancel the busy task when pressing cancel
			if (Event.Key == EKeys::Escape || Event.Key == EKeys::Virtual_Back)
			{
				if (MainMenu.CanCancelBusyTask())
					MainMenu.CancelBusyTask();
				return FEventReply::Handled();
			}
		}

		return Super::OnKeyDown(Geom, Event);
	}
}