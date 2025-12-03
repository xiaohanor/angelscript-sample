class UInitialBoot_PrivacyLicense : UInitialBootSequencePage
{
	UPROPERTY(BindWidget)
	URichTextBlock LicenseText;

	UPROPERTY(BindWidget)
	UMenuPromptOrButton AcceptButton;

	UPROPERTY(EditDefaultsOnly)
	TMap<FString, ULicenseAsset> PrivacyLicenseByPlatform;

	float CurScrollLeft = 0;
	float CurScrollRight = 0;

	bool bPressedButton = false;

	void Show() override
	{
		Super::Show();

		ULicenseAsset LicenseAsset;
		if (!PrivacyLicenseByPlatform.Find(Game::GetPlatformName(), LicenseAsset))
			LicenseAsset = ULicenseAsset();

		if (LicenseAsset == nullptr)
			LicenseAsset = ULicenseAsset();

		FLicenseContent LicenseContent = LicenseAsset.GetLicenseForCulture(Internationalization::GetCurrentCulture());
		LicenseText.SetText(FText::FromString(LicenseContent.Text));
		Scaffold.SetHeading(FText::FromString(LicenseContent.Title));

		if (SplashScreen.ShouldAutoAcceptEULA())
			GoNext();

		AcceptButton.OnPressed.AddUFunction(this, n"GoNext");
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
				GoNext();
			return FEventReply::Handled();
		}
		return FEventReply::Unhandled();
	}

	UFUNCTION()
	void GoNext(UHazeUserWidget Widget = nullptr)
	{
		SplashScreen.InitialBootSequence_Forward();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		float TotalScroll = CurScrollLeft + CurScrollRight;
		if (Math::Abs(TotalScroll) > 0.4)
		{
			float ScrollAmount = 10.0 * TotalScroll;

			UScrollBox TextScrollWidget = Cast<UScrollBox>(LicenseText.Parent.Parent);
			float NewScrollOffset = TextScrollWidget.ScrollOffset + ScrollAmount;
			NewScrollOffset = Math::Clamp(NewScrollOffset, 0.0, TextScrollWidget.ScrollOffsetOfEnd);
			TextScrollWidget.SetScrollOffset(NewScrollOffset);
		}

		if (bNarrateNextTick)
		{
			bNarrateNextTick = false;
			NarrateFullMenu();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnAddedToFocusPath(FFocusEvent InFocusEvent)
	{
		CurScrollLeft = 0.0;
		CurScrollRight = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnRemovedFromFocusPath(FFocusEvent InFocusEvent)
	{
		CurScrollLeft = 0.0;
		CurScrollRight = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnAnalogValueChanged(FGeometry MyGeometry, FAnalogInputEvent InAnalogInputEvent)
	{
		auto GameInst = Game::GetHazeGameInstance();
		if (GameInst == nullptr || !GameInst.bIsInPauseMenu)
		{
			if (Identity != nullptr && !Identity.TakesInputFromController(InAnalogInputEvent.InputDeviceId))
				return FEventReply::Unhandled();
		}

		if (InAnalogInputEvent.Key == EKeys::Gamepad_LeftY)
		{
			CurScrollLeft = -InAnalogInputEvent.AnalogValue;
			return FEventReply::Handled();
		}
		else if (InAnalogInputEvent.Key == EKeys::Gamepad_RightY)
		{
			CurScrollRight = -InAnalogInputEvent.AnalogValue;
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
			if (AcceptButton.IsVisible())
			{
				NarrateString += ", ";
				NarrateString += AcceptButton.Text.ToString();
				NarrateString += ", ";
				NarrateString += Game::KeyToNarrationText(EKeys::Virtual_Accept, Controller).ToString();
			}
		}

		Game::NarrateString(NarrateString);
	}
};