class UInitialBootTelemetryPage : UInitialBootSequencePage
{
	UPROPERTY(BindWidget)
	UMenuPromptOrButton DisableButton;
	UPROPERTY(BindWidget)
	UMenuPromptOrButton EnableButton;

	bool bPressedButton = false;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		DisableButton.OnPressed.AddUFunction(this, n"OnTelemetryDisabled");
		EnableButton.OnPressed.AddUFunction(this, n"OnTelemetryEnabled");
	}

	void Show() override
	{
		Super::Show();

		// Underage identities cannot accept telemetry
		if (Online::IsIdentityUnderage(Identity))
			OnTelemetryDisabled();
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
	private void OnTelemetryDisabled(UHazeUserWidget Widget = nullptr)
	{
		GameSettings::SetGameSettingsValue(n"TelemetryOptIn", "Off");
		SplashScreen.InitialBootSequence_Forward();
	}

	UFUNCTION()
	private void OnTelemetryEnabled(UHazeUserWidget Widget = nullptr)
	{
		GameSettings::SetGameSettingsValue(n"TelemetryOptIn", "On");
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
		else if (InKeyEvent.Key == EKeys::Virtual_Back || InKeyEvent.Key == EKeys::Escape)
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
				OnTelemetryEnabled();
			bPressedButton = false;
			return FEventReply::Handled();
		}
		else if (InKeyEvent.Key == EKeys::Virtual_Back || InKeyEvent.Key == EKeys::Escape)
		{
			if (bPressedButton)
				OnTelemetryDisabled();
			bPressedButton = false;
			return FEventReply::Handled();
		}
		return FEventReply::Unhandled();
	}

	void NarrateFullMenu()
	{
		if (!Game::IsNarrationEnabled())
			return;
			
		FString NarrateString = Scaffold.HeadingText.Text.ToString();

		EHazePlayerControllerType Controller = Lobby::GetMostLikelyControllerType();
		if (Controller != EHazePlayerControllerType::Keyboard)
		{
			if (EnableButton.IsVisible())
			{
				NarrateString += ", ";
				NarrateString += EnableButton.Text.ToString();
				NarrateString += ", ";
				NarrateString += Game::KeyToNarrationText(EKeys::Virtual_Accept, Controller).ToString();
			}

			if (DisableButton.IsVisible())
			{
				NarrateString += ", ";
				NarrateString += DisableButton.Text.ToString();
				NarrateString += ", ";
				NarrateString += Game::KeyToNarrationText(EKeys::Virtual_Back, Controller).ToString();
			}
		}

		Game::NarrateString(NarrateString);
	}
};