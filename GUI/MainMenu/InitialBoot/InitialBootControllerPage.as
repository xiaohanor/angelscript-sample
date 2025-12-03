class UInitialBootControllerPage : UInitialBootSequencePage
{
	UPROPERTY(BindWidget)
	UMenuPromptOrButton ContinueButton;

	bool bPressedButton = false;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		ContinueButton.OnPressed.AddUFunction(this, n"OnContinue");
	}

	void Show() override
	{
		Super::Show();

		// Consoles always use a controller so there's no point to showing this screen
		if (Game::IsConsoleBuild())
			SplashScreen.InitialBootSequence_Forward();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (bNarrateNextTick)
		{
			bNarrateNextTick = false;
			NarrateFullMenu();
		}
	}

	UFUNCTION()
	private void OnContinue(UHazeUserWidget Widget = nullptr)
	{
		SplashScreen.InitialBootSequence_Forward();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (InKeyEvent.Key == EKeys::Virtual_Accept || InKeyEvent.Key == EKeys::Enter)
		{
			bPressedButton = true;
			return FEventReply::Handled();
		}
		return Super::OnKeyDown(MyGeometry, InKeyEvent);
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyUp(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (InKeyEvent.Key == EKeys::Virtual_Accept || InKeyEvent.Key == EKeys::Enter)
		{
			if (bPressedButton)
				OnContinue();
			bPressedButton = false;
			return FEventReply::Handled();
		}
		return FEventReply::Unhandled();
	}

	void NarrateFullMenu()
	{
		if (!Game::IsNarrationEnabled())
			return;
			
		FString NarrateString = "Use of a controller is recommended";

		EHazePlayerControllerType Controller = Lobby::GetMostLikelyControllerType();
		if (Controller != EHazePlayerControllerType::Keyboard)
		{
			if (ContinueButton.IsVisible())
			{
				NarrateString += ", ";
				NarrateString += ContinueButton.Text.ToString();
				NarrateString += ", ";
				NarrateString += Game::KeyToNarrationText(EKeys::Virtual_Accept, Controller).ToString();
			}
		}

		Game::NarrateString(NarrateString);
	}
};