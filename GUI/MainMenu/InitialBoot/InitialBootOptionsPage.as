
class UInitialBootOptionsPage : UInitialBootSequencePage
{
	UOptionWidget FocusedOption;
	TArray<UOptionWidget> Options;

	UPROPERTY(BindWidget)
	UMenuPromptOrButton BackButton;
	UPROPERTY(BindWidget)
	UMenuPromptOrButton ContinueButton;

	UPROPERTY(EditAnywhere)
	bool bCanGoBackToPrevious = false;

	bool bPressedButton = false;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		// Collect all options on this page
		TArray<UWidget> Widgets;
		GetAllChildWidgetsOfClass(UOptionWidget, Widgets);

		for (auto Widget : Widgets)
			Options.Add(Cast<UOptionWidget>(Widget));

		// Respond to events on options
		for (auto Option : Options)
		{
			Option.OnOptionFocused.AddUFunction(this, n"OnFocusedOptionRow");
		}

		if (!bCanGoBackToPrevious)
			BackButton.SetVisibility(ESlateVisibility::Hidden);

		ContinueButton.OnPressed.AddUFunction(this, n"OnContinuePage");
		BackButton.OnPressed.AddUFunction(this, n"OnBackPage");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (FocusedOption != nullptr && FocusedOption.IsHoveredOrActive())
		{
			Scaffold.SetTooltip(FocusedOption.GetDescription(), FocusedOption.CachedGeometry);
		}
		else
		{
			Scaffold.ClearTooltip();
		}

		if (bNarrateNextTick)
		{
			bNarrateNextTick = false;
			NarrateFullMenu();
		}
	}

	void NarrateFullMenu()
	{
		if (!Game::IsNarrationEnabled())
			return;
			
		FString NarrateString = Scaffold.HeadingText.Text.ToString();
		if (FocusedOption != nullptr)
		{
			NarrateString += ", " + FocusedOption.GetFullNarrationText();
		}

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

			if (BackButton.IsVisible())
			{
				NarrateString += ", ";
				NarrateString += BackButton.Text.ToString();
				NarrateString += ", ";
				NarrateString += Game::KeyToNarrationText(EKeys::Virtual_Back, Controller).ToString();
			}
		}

		Game::NarrateString(NarrateString);
	}
	

	UFUNCTION()
	protected void OnFocusedOptionRow(UOptionWidget Widget)
	{
		FocusedOption = Widget;
		Scaffold.SetTooltip(Widget.GetDescription(), FocusedOption.CachedGeometry);
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry MyGeometry, FFocusEvent InFocusEvent)
	{
		if (FocusedOption != nullptr && FocusedOption.IsVisible())
			return FEventReply::Handled().SetUserFocus(FocusedOption, InFocusEvent.Cause);
		for (auto Option : Options)
		{
			if (Option.IsVisible())
				return FEventReply::Handled().SetUserFocus(Option, InFocusEvent.Cause);
		}
		return FEventReply::Unhandled();
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
				OnContinuePage();
			bPressedButton = false;
			return FEventReply::Handled();
		}
		else if (InKeyEvent.Key == EKeys::Virtual_Back || InKeyEvent.Key == EKeys::Escape)
		{
			if (bPressedButton)
				OnBackPage();
			bPressedButton = false;
			return FEventReply::Handled();
		}
		return FEventReply::Unhandled();
	}

	UFUNCTION()
	void OnContinuePage(UHazeUserWidget Widget = nullptr)
	{
		SplashScreen.InitialBootSequence_Forward();
	}

	UFUNCTION()
	void OnBackPage(UHazeUserWidget Widget = nullptr)
	{
		if (!bCanGoBackToPrevious)
			return;
		SplashScreen.InitialBootSequence_Back();
	}
};