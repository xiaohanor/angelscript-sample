class UInitialBoot_EULA : UInitialBootSequencePage
{
	UPROPERTY(BindWidget)
	URichTextBlock LicenseText;

	UPROPERTY(BindWidget)
	UMenuPromptOrButton DeclineButton;

	UPROPERTY(BindWidget)
	UHazeTextWidget QuestionPrompt;

	UPROPERTY(BindWidget)
	UMenuPromptOrButton AcceptButton;

	UPROPERTY(EditDefaultsOnly)
	TMap<FString, ULicenseAsset> EULALicenseByPlatform;

	float CurScrollLeft = 0;
	float CurScrollRight = 0;

	bool bPressedButton = false;

	void Show() override
	{
		Super::Show();

		ULicenseAsset LicenseAsset;
		if (!EULALicenseByPlatform.Find(Game::GetPlatformName(), LicenseAsset))
			LicenseAsset = ULicenseAsset();

		if (LicenseAsset == nullptr)
			LicenseAsset = ULicenseAsset();

		FLicenseContent LicenseContent = LicenseAsset.GetLicenseForCulture(Internationalization::GetCurrentCulture());
		LicenseText.SetText(FText::FromString(LicenseContent.Text));
		Scaffold.SetHeading(FText::FromString(LicenseContent.Title));

		if (SplashScreen.ShouldAutoAcceptEULA())
			AcceptEULA();

		AcceptButton.OnPressed.AddUFunction(this, n"AcceptEULA");
		DeclineButton.OnPressed.AddUFunction(this, n"DeclineEULA");

		// Nintendo cannot separate GDPR+/ROW, need to use the combined version
		if (Game::IsPlatformSage())
		{
			QuestionPrompt.Text = NSLOCTEXT("EULA", "AcceptQuestion_Combined", "I accept the User Agreement and acknowledge that EA's Privacy and Cookie Policy applies to my use of EA's services. If I am outside the United States, I consent to this personal data being transferred to EA in the United States, as further explained in the Privacy and Cookie Policy.");
			QuestionPrompt.Update();

			AcceptButton.Text = NSLOCTEXT("EULA", "AcceptButton_Combined", "Continue");
			AcceptButton.Update();

			DeclineButton.Text = NSLOCTEXT("EULA", "DeclineButton_Combined", "Cancel");
			DeclineButton.Update();
		}
		else if (Online::IsEUBuild(Identity))
		{
			QuestionPrompt.Text = NSLOCTEXT("EULA", "AcceptQuestion_EU", "I accept the User Agreement and understand EA's Privacy and Cookie Policy applies to my use of EA's services. I consent to any personal data collected through my use of EA's services being transferred to EA in the United States, as further explained in the Privacy and Cookie Policy.");
			QuestionPrompt.Update();

			AcceptButton.Text = NSLOCTEXT("EULA", "AcceptButton_EU", "Continue");
			AcceptButton.Update();

			DeclineButton.Text = NSLOCTEXT("EULA", "DeclineButton_EU", "Cancel");
			DeclineButton.Update();
		}
		else
		{
			QuestionPrompt.Text = NSLOCTEXT("EULA", "AcceptQuestion_WW", "I have read and accept the User Agreement and EA's Privacy and Cookie Policy.");
			QuestionPrompt.Update();

			AcceptButton.Text = NSLOCTEXT("EULA", "AcceptButton_WW", "Accept");
			AcceptButton.Update();

			DeclineButton.Text = NSLOCTEXT("EULA", "DeclineButton_WW", "Decline");
			DeclineButton.Update();
		}
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
				AcceptEULA();
			bPressedButton = false;
			return FEventReply::Handled();
		}
		else if (InKeyEvent.Key == EKeys::Virtual_Back || InKeyEvent.Key == EKeys::Escape)
		{
			if (bPressedButton)
				DeclineEULA();
			bPressedButton = false;
			return FEventReply::Handled();
		}
		return FEventReply::Unhandled();
	}

	UFUNCTION()
	void AcceptEULA(UHazeUserWidget Widget = nullptr)
	{
		Profile::SetProfileValue(SplashScreen.PendingIdentity, n"EULA_Accepted", "true");
		SplashScreen.InitialBootSequence_Forward();
	}

	UFUNCTION()
	void DeclineEULA(UHazeUserWidget Widget = nullptr)
	{
		FMessageDialog Dialog;
		// Nintendo cannot separate GDPR+/ROW, need to use the combined version
		if (Game::IsPlatformSage())
			Dialog.Message = NSLOCTEXT("EULA", "DeclinePrompt_Combined", "You must accept the User Agreement to play this game. You acknowledge that EA's Privacy & Cookie Policy applies.");
		else if (Online::IsEUBuild(Identity))
			Dialog.Message = NSLOCTEXT("EULA", "DeclinePrompt_EU", "You must accept the User Agreement to play this game. You understand EA's Privacy & Cookie Policy applies.");
		else
			Dialog.Message = NSLOCTEXT("EULA", "DeclinePrompt_WW", "You must accept the User Agreement and EA's Privacy & Cookie Policy to play this game.");

		if (!Game::IsConsoleBuild())
		{
			Dialog.AddOption(NSLOCTEXT("EULA", "Decline_Continue", "Continue"), FOnMessageDialogOptionChosen(this, n"DeclineEULA_Continue"));
			Dialog.AddOption(NSLOCTEXT("EULA", "Decline_Exit", "Quit Game"), FOnMessageDialogOptionChosen(this, n"DeclineEULA_Quit"));
		}
		else
		{
			Dialog.AddOKOption(FOnMessageDialogOptionChosen(this, n"DeclineEULA_Continue"));
		}

		ShowPopupMessage(Dialog, this);
	}

	UFUNCTION()
	void DeclineEULA_Continue()
	{
		Profile::SetProfileValue(SplashScreen.PendingIdentity, n"EULA_Accepted", "false");
		SplashScreen.CancelInitialBootSequence();
	}

	UFUNCTION()
	void DeclineEULA_Quit()
	{
		Profile::SetProfileValue(SplashScreen.PendingIdentity, n"EULA_Accepted", "false");
		Game::QuitGame();
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

			if (DeclineButton.IsVisible())
			{
				NarrateString += ", ";
				NarrateString += DeclineButton.Text.ToString();
				NarrateString += ", ";
				NarrateString += Game::KeyToNarrationText(EKeys::Virtual_Back, Controller).ToString();
			}
		}

		Game::NarrateString(NarrateString);
	}
};