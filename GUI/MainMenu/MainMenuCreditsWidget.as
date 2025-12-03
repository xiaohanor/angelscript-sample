class UMainMenuCreditsWidget : UMainMenuStateWidget
{
	UPROPERTY(BindWidget)
	UCreditsWidget CreditsWidget;

	bool bLeftShoulderHeld = false;
	bool bRightShoulderHeld = false;

	void OnTransitionEnter(EMainMenuState PreviousState, bool bSnap) override
	{
		Super::OnTransitionEnter(PreviousState, bSnap);

		CreditsWidget.OnCreditsFinishedPlaying.Clear();
		CreditsWidget.OnCreditsFinishedPlaying.AddUFunction(this, n"OnCreditsFinished");
		CreditsWidget.PlayCreditsFromStart();
	}

	UFUNCTION()
	void OnCreditsFinished()
	{
		MainMenu.ReturnToMainMenu();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		Super::Tick(MyGeometry, InDeltaTime);
		if (!bIsActive)
			return;

		if (bLeftShoulderHeld && bRightShoulderHeld)
			CreditsWidget.SpeedMultiplier = 10.0; 
		else
			CreditsWidget.SpeedMultiplier = 1.0; 
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry Geom, FKeyEvent Event)
	{
		if (MainMenu.IsOwnerInput(Event))
		{
			// Try to cancel the busy task when pressing cancel
			if (Event.Key == EKeys::Escape || Event.Key == EKeys::Virtual_Back)
			{
				MainMenu.ReturnToMainMenu();
				return FEventReply::Handled();
			}

			// Speed up with LB+RB
			if (Event.Key == EKeys::Gamepad_LeftShoulder)
			{
				bLeftShoulderHeld = true;
				return FEventReply::Handled();
			}

			if (Event.Key == EKeys::Gamepad_RightShoulder)
			{
				bRightShoulderHeld = true;
				return FEventReply::Handled();
			}
		}

		return Super::OnKeyDown(Geom, Event);
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyUp(FGeometry Geom, FKeyEvent Event)
	{
		if (MainMenu.IsOwnerInput(Event))
		{
			// Speed up with LB+RB
			if (Event.Key == EKeys::Gamepad_LeftShoulder)
			{
				bLeftShoulderHeld = false;
				return FEventReply::Handled();
			}

			if (Event.Key == EKeys::Gamepad_RightShoulder)
			{
				bRightShoulderHeld = false;
				return FEventReply::Handled();
			}
		}

		return FEventReply::Unhandled();
	}
};