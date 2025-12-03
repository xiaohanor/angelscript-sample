const FConsoleVariable CVar_AlwaysShowEULA("Haze.AlwaysShowEULA", 0);
const FConsoleCommand Command_ResetEULA("Haze.ResetEULA", n"ResetEULA");

class USplashScreenWidget : UMainMenuStateWidget
{
	UPROPERTY()
	UHazePlayerIdentity PendingIdentity;

	UPROPERTY()
	UBinkMediaPlayer SplashBink;

	UPROPERTY(EditDefaultsOnly)
	TArray<TSubclassOf<UInitialBootSequencePage>> InitialBootSequencePages;

	UPROPERTY(BindWidget)
	UWidget BackgroundLogo;
	UPROPERTY(BindWidget)
	UWidget PromptContainer;
	UPROPERTY(BindWidget)
	UHazeTextWidget ButtonPrompt;

	UPROPERTY(BindWidget)
	UWidget LoadingContainer;

	UPROPERTY(BindWidget)
	UWidget ChangeIdentityPrompt;
	UPROPERTY(BindWidget)
	UMenuPromptOrButton ChangeIdentityButton;
	UPROPERTY(BindWidget)
	UHazeTextWidget AccountNameText;

	bool bSnapToMainMenu = false;
	bool bHasEverShownEULA = false;
	bool bIsLoadingIdentity = false;
	float TransitionedToTime = 0.0;

	UInitialBootSequencePage BootSequencePage;
	int BootSequencePageIndex = -1;

	TArray<FKey> ExcludedKeys;
	default ExcludedKeys.Add(EKeys::Gamepad_LeftStick_Down);
	default ExcludedKeys.Add(EKeys::Gamepad_LeftStick_Up);
	default ExcludedKeys.Add(EKeys::Gamepad_LeftStick_Left);
	default ExcludedKeys.Add(EKeys::Gamepad_LeftStick_Right);
	default ExcludedKeys.Add(EKeys::Gamepad_RightStick_Down);
	default ExcludedKeys.Add(EKeys::Gamepad_RightStick_Up);
	default ExcludedKeys.Add(EKeys::Gamepad_RightStick_Left);
	default ExcludedKeys.Add(EKeys::Gamepad_RightStick_Right);
	default ExcludedKeys.Add(EKeys::LeftAlt);
	default ExcludedKeys.Add(EKeys::RightAlt);
	default ExcludedKeys.Add(EKeys::LeftControl);
	default ExcludedKeys.Add(EKeys::RightControl);
	default ExcludedKeys.Add(EKeys::LeftShift);
	default ExcludedKeys.Add(EKeys::RightShift);

	private bool bNarrateNextTick = false;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		if (Game::PlatformName == "PS5")
		{
			// Playstation needs a separate localization string for the word "Button"
			// In some languages, Playstation wants a special different translation for "Button"
			ButtonPrompt.SetText(NSLOCTEXT("SplashScreen", "AnyButtonPrompt_Playstation", "Press any button to continue..."));
		}
		else if (Game::PlatformName == "Sage")
		{
			// In some languages, Nintendo wants a special different translation for "Button"
			ButtonPrompt.SetText(NSLOCTEXT("SplashScreen", "AnyButtonPrompt_Sage", "Press any button to continue..."));
		}
		else
		{
			ButtonPrompt.SetText(NSLOCTEXT("SplashScreen", "AnyButtonPrompt", "Press any button to continue..."));
		}
	}

	void OnTransitionEnter(EMainMenuState PreviousState, bool bSnap) override
	{
		Super::OnTransitionEnter(PreviousState, bSnap);

		// View is faded out during splash
		MainMenu.CameraUser.FadeOutView(0.0);
		PromptContainer.SetRenderOpacity(0.0);

		TransitionedToTime = Time::RealTimeSeconds;

#if EDITOR
		FName CurrentLanguage = Editor::GetGameLocalizationPreviewLanguage();
#else
		FName CurrentLanguage = FName(Internationalization::GetCurrentLanguage());
#endif

		if (CurrentLanguage == n"zh-Hans")
			SplashBink.OpenUrl("./Movies/menu_splash_60_hans.bk2");
		else if (CurrentLanguage == n"zh-Hant")
			SplashBink.OpenUrl("./Movies/menu_splash_60_hant.bk2");
		else
			SplashBink.OpenUrl("./Movies/menu_splash_60.bk2");

		SplashBink.Seek(FTimespan(0, 0, 0));
		SplashBink.Play();

		// Take focus for *all* users, since we need players to be able to confirm
		Widget::SetAllPlayerUIFocus(this);

		// If a primary identity is already set, use it
		if (Online::PrimaryIdentity != nullptr)
		{
			PendingIdentity = Online::PrimaryIdentity;
			bSnapToMainMenu = true;
			ProceedTakeMenuOwner();
		}
		else
		{
			bSnapToMainMenu = false;
			bNarrateNextTick = true;
		}

		UpdateWidget();
	}

	void OnTransitionExit(EMainMenuState NextState, bool bSnap) override
	{
		Super::OnTransitionExit(NextState, bSnap);
		SplashBink.Stop();

		if (bSnap)
			MainMenu.CameraUser.FadeInView(0.0);
		else
			MainMenu.CameraUser.FadeInView(1.0);
	}

	UFUNCTION(BlueprintPure)
	bool ShouldShowAccountPicker()
	{
		if (CVar_AlwaysShowEULA.GetInt() == 0)
		{
			if (!Online::RequiresIdentityEngagement())
				return false;
			if (!Game::IsConsoleBuild())
				return false;
		}

		if (PendingIdentity == nullptr)
			return false;

		if (BootSequencePage != nullptr)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geom, float DeltaTime)
	{
		Super::Tick(Geom, DeltaTime);

		if (!bIsActive)
			return;

		float ActiveTime = Time::GetRealTimeSince(TransitionedToTime);
		PromptContainer.SetRenderOpacity(Math::Lerp(0.0, 1.0, Math::Saturate(ActiveTime - 2.0)));

		if (PendingIdentity == nullptr && Online::PrimaryIdentity != nullptr && bIsActive)
		{
			PendingIdentity = Online::PrimaryIdentity;
			bSnapToMainMenu = true;
			ProceedTakeMenuOwner();
		}

		// Drop out of the first boot sequence if we lost identity engagement during it
		if (BootSequencePage != nullptr &&
			(PendingIdentity == nullptr
			|| !Online::IsIdentitySignedIn(PendingIdentity)
			|| PendingIdentity.GetEngagement() != EHazeIdentityEngagement::Engaged))
		{
			CancelInitialBootSequence();
		}

		UpdateWidget();

		if (bNarrateNextTick)
		{
			bNarrateNextTick = false;
			if (Game::IsNarrationEnabled())
			{
				Game::NarrateText(FText::FromString("Press any button to continue"));
			}
		}
	}

	void UpdateWidget()
	{
		if (PendingIdentity == nullptr && !bIsLoadingIdentity)
		{
			PromptContainer.SetVisibility(ESlateVisibility::Visible);
			BackgroundLogo.SetVisibility(ESlateVisibility::Visible);
		}
		else
		{
			PromptContainer.SetVisibility(ESlateVisibility::Hidden);
			BackgroundLogo.SetVisibility(ESlateVisibility::Hidden);
		}

		if (bIsLoadingIdentity)
			LoadingContainer.SetVisibility(ESlateVisibility::Visible);
		else
			LoadingContainer.SetVisibility(ESlateVisibility::Hidden);

		if (ShouldShowAccountPicker())
		{
			ChangeIdentityPrompt.SetVisibility(ESlateVisibility::Visible);
			AccountNameText.Text = PendingIdentity.GetPlayerName();
			AccountNameText.Update();
		}
		else
		{
			ChangeIdentityPrompt.SetVisibility(ESlateVisibility::Hidden);
		}
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry Geom, FKeyEvent Event)
	{
		auto Identity = Online::GetMainMenuIdentityAssociatedWithInputDevice(Event.InputDeviceId);

		if (Console::IsConsoleActive() || Console::IsConsoleKey(Event.Key))
			return FEventReply::Unhandled();

		if (!bIsActive)
			return FEventReply::Unhandled();

		if (IsMessageDialogShown() || Event.IsRepeat())
			return FEventReply::Unhandled();

		// Don't absorb anything if this is input without an identity,
		// this can happen on console platforms with keyboards.
		if (Identity == nullptr)
			return FEventReply::Unhandled();

		// We can't confirm with axes
		if (ExcludedKeys.Contains(Event.Key))
			return FEventReply::Unhandled();

		// Don't allow presses until a bit after the splash screen shows
		if (Time::GetRealTimeSince(TransitionedToTime) < 2.0)
			return FEventReply::Unhandled();

		// Don't absorb certain special keys
		if (Event.Key == EKeys::Escape || Event.Key == EKeys::Gamepad_Special_Left || Event.Key == EKeys::Tab || Event.Key == EKeys::Virtual_Back)
			return FEventReply::Unhandled();

		// Don't absorb if focus is something outside of the game (ie console)
		if (Widget::IsPlayerUIFocusOutsideGame(Identity))
			return FEventReply::Unhandled();

		if (MainMenu.OwnerIdentity == nullptr && PendingIdentity == nullptr)
		{
			PendingIdentity = Identity;
			PendingIdentity.OnInputTakenFromController(Event.InputDeviceId, true);
			ProceedTakeMenuOwner();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonUp(FGeometry Geom, FPointerEvent Event)
	{
		auto Identity = Online::GetMainMenuIdentityAssociatedWithInputDevice(Event.InputDeviceId);
		if (BootSequencePage != nullptr || IsMessageDialogShown())
			return FEventReply::Unhandled();

		// Don't allow presses until a bit after the splash screen shows
		if (Time::GetRealTimeSince(TransitionedToTime) < 2.0)
			return FEventReply::Unhandled();

		if ((Event.EffectingButton == EKeys::LeftMouseButton
			|| Event.EffectingButton == EKeys::RightMouseButton)
			&& (PendingIdentity == nullptr && MainMenu.OwnerIdentity == nullptr))
		{
			PendingIdentity = Identity;
			ProceedTakeMenuOwner();

			return FEventReply::Handled();
		}
		return FEventReply::Unhandled();
	}

	UFUNCTION()
	private void ProceedTakeMenuOwner()
	{
		if (MainMenu.OwnerIdentity != nullptr)
			return;
		if (PendingIdentity == nullptr)
			return;
		if (BootSequencePage != nullptr)
			return;

		// Make sure we're signed in before allowing to use the main menu
		if (!Online::IsIdentitySignedIn(PendingIdentity))
		{
			auto SignInWithIdentity = PendingIdentity;
			PendingIdentity = nullptr;
			bIsLoadingIdentity = true;
			Online::PromptIdentitySignIn(SignInWithIdentity, true, FHazeOnOnlineIdentitySignedIn(this, n"OnIdentitySignedIn"));
			return;
		}

		// Make sure the profile is loaded before we proceed to the menu
		if (!Profile::IsProfileLoaded(PendingIdentity))
		{
			bIsLoadingIdentity = true;
			Profile::LoadProfile(PendingIdentity, FHazeOnProfileLoaded(this, n"OnIdentityProfileLoaded"));
			return;
		}

		FString EULAValue;
		if (!Profile::GetProfileValue(PendingIdentity, n"EULA_Accepted", EULAValue) || EULAValue != "true"
			|| (CVar_AlwaysShowEULA.GetInt() != 0 && !bHasEverShownEULA))
		{
			bHasEverShownEULA = true;
			StartInitialBootSequence();
			return;
		}

		// All steps completed!
		auto FinishedIdentity = PendingIdentity;
		PendingIdentity = nullptr;
		MainMenu.ConfirmMenuOwner(FinishedIdentity, bSnapToMainMenu);
	}

	bool ShouldAutoAcceptEULA()
	{
		// When we're debugging EULA we should show it regardless
		if (CVar_AlwaysShowEULA.GetInt() != 0)
			return false;

		// On console we should show EULA on first boot
		if (Game::IsConsoleBuild())
			return false;

		// On PC we don't need to show EULA, Origin has done it for us
		return true;
	}

	UFUNCTION()
	void OnIdentityProfileLoaded(UHazePlayerIdentity Identity)
	{
		bIsLoadingIdentity = false;
		ProceedTakeMenuOwner();
	}

	UFUNCTION()
	void OnIdentitySignedIn(UHazePlayerIdentity Identity, bool bSuccess)
	{
		bIsLoadingIdentity = false;
		if (bSuccess && PendingIdentity == nullptr)
		{
			PendingIdentity = Identity;
			ProceedTakeMenuOwner();
		}
	}

	UFUNCTION()
	void OnPendingIdentityChanged(UHazePlayerIdentity Identity, bool bSuccess)
	{
		if (!bSuccess)
			return;
		if (PendingIdentity == Identity)
			return;

		CancelInitialBootSequence();
		PendingIdentity = Identity;
		ProceedTakeMenuOwner();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDown(FGeometry Geom, FPointerEvent Event)
	{
		if (BootSequencePage != nullptr || IsMessageDialogShown())
			return FEventReply::Unhandled();

		// Always focus the splash when clicked
		return FEventReply::Handled().SetUserFocus(this, bAllUsers = true);
	}

	void StartInitialBootSequence()
	{
		GameSettings::SetGameSettingsProfile(PendingIdentity, false);

		BootSequencePageIndex = -1;
		InitialBootSequence_Forward();
	}

	void InitialBootSequence_Back()
	{
		if (BootSequencePage != nullptr)
		{
			Widget::RemoveFullscreenWidget(BootSequencePage);
			BootSequencePage = nullptr;
		}

		BootSequencePageIndex -= 1;
		if (InitialBootSequencePages.IsValidIndex(BootSequencePageIndex))
		{
			BootSequencePage = Cast<UInitialBootSequencePage>(
				Widget::AddFullscreenWidget(InitialBootSequencePages[BootSequencePageIndex], EHazeWidgetLayer::Menu));
			BootSequencePage.SplashScreen = this;
			BootSequencePage.Identity = PendingIdentity;
			Widget::SetAllPlayerUIFocus(BootSequencePage);
			BootSequencePage.SetWidgetZOrderInLayer(-110);
			BootSequencePage.Show();
			SetVisibility(ESlateVisibility::HitTestInvisible);

			UMenuEffectEventHandler::Trigger_OnBootMenuChanged(Menu::GetAudioActor(), FBootMenuStateChangeData(BootSequencePage));
		}
		else
		{
			BootSequencePageIndex = -1;

			PendingIdentity = nullptr;
			bIsLoadingIdentity = false;
			Widget::SetAllPlayerUIFocus(this);
			Online::SetPrimaryIdentity(nullptr);
			SetVisibility(ESlateVisibility::Visible);
		}
	}

	void InitialBootSequence_Forward()
	{
		BootSequencePageIndex += 1;
		if (BootSequencePage != nullptr)
		{
			Widget::RemoveFullscreenWidget(BootSequencePage);
			BootSequencePage = nullptr;
		}

		if (InitialBootSequencePages.IsValidIndex(BootSequencePageIndex))
		{
			BootSequencePage = Cast<UInitialBootSequencePage>(
				Widget::AddFullscreenWidget(InitialBootSequencePages[BootSequencePageIndex], EHazeWidgetLayer::Menu));
			BootSequencePage.SplashScreen = this;
			BootSequencePage.Identity = PendingIdentity;
			Widget::SetAllPlayerUIFocus(BootSequencePage);
			BootSequencePage.SetWidgetZOrderInLayer(-110);
			BootSequencePage.Show();
			SetVisibility(ESlateVisibility::HitTestInvisible);

			UMenuEffectEventHandler::Trigger_OnBootMenuChanged(Menu::GetAudioActor(), FBootMenuStateChangeData(BootSequencePage));
		}
		else
		{
			Widget::SetAllPlayerUIFocus(this);
			ProceedTakeMenuOwner();
			SetVisibility(ESlateVisibility::Visible);
		}
	}

	void CancelInitialBootSequence()
	{
		PendingIdentity = nullptr;
		bIsLoadingIdentity = false;
		bHasEverShownEULA = false;
		Widget::SetAllPlayerUIFocus(this);
		Online::SetPrimaryIdentity(nullptr);
		SetVisibility(ESlateVisibility::Visible);

		if (BootSequencePage != nullptr)
		{
			Widget::RemoveFullscreenWidget(BootSequencePage);
			BootSequencePage = nullptr;
		}

		BootSequencePageIndex = -1;
	}
};

void ResetEULA(const TArray<FString>& Args)
{
	auto Identity = Online::GetPrimaryIdentity();
	if (Identity != nullptr)
		Profile::SetProfileValue(Identity, n"EULA_Accepted", "false");
}