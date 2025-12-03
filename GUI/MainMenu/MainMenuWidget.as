class UMainMenuWidget : UMainMenuStateWidget
{
	UPROPERTY(BindWidget)
	UMainMenuButton PlayLocalButton;
	UPROPERTY(BindWidget)
	UMainMenuButton PlayLocalWirelessButton;
	UPROPERTY(BindWidget)
	UMainMenuButton PlayOnlineButton;
	UPROPERTY(BindWidget)
	UMainMenuButton DevJoinButton;
	UPROPERTY(BindWidget)
	UMainMenuButton DevMenuButton;
	UPROPERTY(BindWidget)
	UMainMenuButton OptionsButton;
	// UPROPERTY(BindWidget)
	// UMainMenuButton AccessibilityButton;
	UPROPERTY(BindWidget)
	UMainMenuButton CreditsButton;
	UPROPERTY(BindWidget)
	UMainMenuButton QuitButton;

	UPROPERTY(BindWidget)
	UMainMenuButton PurchaseGameButton;
	UPROPERTY(BindWidget)
	UMainMenuButton FriendsPassInfoButton;

	UPROPERTY(BindWidget)
	UWidget ChangeIdentityPrompt;
	UPROPERTY(BindWidget)
	UMenuPromptOrButton ChangeIdentityButton;
	UPROPERTY(BindWidget)
	UHazeTextWidget AccountNameText;

	UPROPERTY(BindWidget)
	UWidget FriendsPassContainer;

	UPROPERTY(BindWidget)
	UWidget EASignInContainer;
	UPROPERTY(BindWidget)
	UMenuPromptOrButton EASignInButton;
	UPROPERTY(BindWidget)
	UTextBlock EASignInPromptText;

	private EHazeEntitlement PrevEntitlement = EHazeEntitlement::FullGame;
	private bool bChangeIdentityPressed = false;

	void OnTransitionEnter(EMainMenuState PreviousState, bool bSnap) override
	{
		Super::OnTransitionEnter(PreviousState, bSnap);

		PlayLocalButton.OnClicked.AddUFunction(this, n"OnPlayLocal");
		PlayLocalWirelessButton.OnClicked.AddUFunction(this, n"OnPlayLocalWireless");
		PlayOnlineButton.OnClicked.AddUFunction(this, n"OnPlayOnline");
		DevJoinButton.OnClicked.AddUFunction(this, n"OnDevJoin");
		DevMenuButton.OnClicked.AddUFunction(this, n"OnDevMenu");
		OptionsButton.OnClicked.AddUFunction(this, n"OnOptions");
		// AccessibilityButton.OnClicked.AddUFunction(this, n"OnAccessibility");
		CreditsButton.OnClicked.AddUFunction(this, n"OnCredits");
		QuitButton.OnClicked.AddUFunction(this, n"OnQuit");

		PurchaseGameButton.OnClicked.AddUFunction(this, n"OnPurchaseGame");
		FriendsPassInfoButton.OnClicked.AddUFunction(this, n"OnFriendsPassInfo");

#if !RELEASE
		if (!Debug::IsUXTestBuild())
			DevMenuButton.SetVisibility(ESlateVisibility::Visible);
		else
			DevMenuButton.SetVisibility(ESlateVisibility::Collapsed);
#else
			DevMenuButton.SetVisibility(ESlateVisibility::Collapsed);
#endif

		if (Game::PlatformName != "Sage")
			PlayLocalWirelessButton.SetVisibility(ESlateVisibility::Collapsed);

		if (Game::IsConsoleBuild())
		{
			CreditsButton.bIsLastOption = true;
			QuitButton.SetVisibility(ESlateVisibility::Collapsed);
		}
		else
		{
			EASignInPromptText.SetText(
				NSLOCTEXT("MainMenu", "EASignInPrompt", "Sign in to an EA account to receive game invites from friends on any platform.")
			);
		}

		if (!Online::HasActiveJoinPrompt())
			DevJoinButton.SetVisibility(ESlateVisibility::Collapsed);

		if (!CanChangeIdentity())
			ChangeIdentityPrompt.SetVisibility(ESlateVisibility::Collapsed);

		AccountNameText.Text = MainMenu.OwnerIdentity.GetPlayerName();
		AccountNameText.Update();
		ChangeIdentityButton.OnPressed.AddUFunction(this, n"OnChangeIdentity");

		UpdateEntitlement();

		EASignInButton.OnPressed.AddUFunction(this, n"OnEASignIn");

		if (PreviousState == EMainMenuState::Options)
			Widget::SetAllPlayerUIFocus(OptionsButton);
		else if (PreviousState == EMainMenuState::Credits)
			Widget::SetAllPlayerUIFocus(CreditsButton);
		else if (PrevEntitlement == EHazeEntitlement::FriendPass)
			Widget::SetAllPlayerUIFocus(PurchaseGameButton);
		else
			Widget::SetAllPlayerUIFocus(PlayLocalButton);

		if (PreviousState == EMainMenuState::Splash && !bSnap)
		{
			TArray<UMainMenuButton> AllButtons;
			AllButtons.Add(PurchaseGameButton);
			AllButtons.Add(FriendsPassInfoButton);
			AllButtons.Add(PlayLocalButton);
			AllButtons.Add(PlayLocalWirelessButton);
			AllButtons.Add(PlayOnlineButton);
			AllButtons.Add(DevJoinButton);
			AllButtons.Add(DevMenuButton);
			AllButtons.Add(OptionsButton);
			AllButtons.Add(CreditsButton);
			AllButtons.Add(QuitButton);

			float Delay = 0.0;
			for (UMainMenuButton Button : AllButtons)
			{
				if (Button.IsVisible())
				{
					Button.AnimateVisible(Delay);
					Delay += 0.05;
				}
			}
		}
	}

	void OnTransitionExit(EMainMenuState NextState, bool bSnap) override
	{
		ClosePopupMessageByInstigator(this);
		Super::OnTransitionExit(NextState, bSnap);
	}

	UFUNCTION()
	private void OnFriendsPassInfo(UMenuButtonWidget Button)
	{
		Online::ShowFriendsPassInfo();
	}

	UFUNCTION()
	private void OnPurchaseGame(UMenuButtonWidget Button)
	{
		Telemetry::TriggerImmediateSpecialEvent("mainmenu_upsell_clicked");
		Online::ShowStorePage();
	}

	UFUNCTION()
	private void OnEASignIn(UHazeUserWidget Widget = nullptr)
	{
		Online::PerformEASignIn();
	}

	UFUNCTION()
	private void OnChangeIdentity(UHazeUserWidget Widget = nullptr)
	{
		Online::SetPrimaryIdentity(nullptr);
		Online::PromptIdentitySignIn(MainMenu.OwnerIdentity, true, FHazeOnOnlineIdentitySignedIn(this, n"OnIdentitySwitched"));
	}

	bool CanChangeIdentity()
	{
		return Online::RequiresIdentityEngagement() && Game::IsConsoleBuild();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry Geom, FKeyEvent Event)
	{
		if (MainMenu.IsOwnerInput(Event) && !Event.IsRepeat())
		{
			// Go back to splash when pressing B
			if (Event.Key == EKeys::Escape || Event.Key == EKeys::Virtual_Back)
			{
				MainMenu.ReturnToSplashScreen(bSnap = false);
				return FEventReply::Handled();
			}

			// Switch accounts when pressing Y
			if (Event.Key == EKeys::Gamepad_FaceButton_Top && CanChangeIdentity() && bIsActive)
			{
				bChangeIdentityPressed = true;
				return FEventReply::Handled();
			}

			// Sign in to EA account when pressing X
			if (Event.Key == EKeys::Gamepad_FaceButton_Left && Online::ShouldShowRequestEASignIn())
			{
				OnEASignIn();
				return FEventReply::Handled();
			}

			// Accesibility options with LB
			if (Event.Key == EKeys::Gamepad_LeftShoulder)
			{
				return FEventReply::Handled();
			}
		}

		return Super::OnKeyDown(Geom, Event);
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyUp(FGeometry Geom, FKeyEvent Event)
	{
		if (MainMenu.IsOwnerInput(Event) && !Event.IsRepeat())
		{
			// Accesibility optionst with LB
			if (Event.Key == EKeys::Gamepad_LeftShoulder)
			{
				// TODO
				//MainMenu_AccessibilityOptions();
				return FEventReply::Handled();
			}

			// Switch accounts when pressing Y
			if (Event.Key == EKeys::Gamepad_FaceButton_Top && CanChangeIdentity() && bIsActive)
			{
				if (bChangeIdentityPressed)
				{
					bChangeIdentityPressed = false;
					OnChangeIdentity();
				}
				return FEventReply::Handled();
			}
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION()
	void OnIdentitySwitched(UHazePlayerIdentity Identity, bool bSuccess)
	{
		if (bSuccess)
			MainMenu.ReturnToSplashScreen(Identity, bSnap = true);
		else
			Online::SetPrimaryIdentity(MainMenu.OwnerIdentity);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		Super::Tick(MyGeometry, InDeltaTime);

		auto CurEntitlement = Online::GetGameEntitlement();
		if (CurEntitlement != PrevEntitlement)
		{
			PrevEntitlement = Online::GetGameEntitlement();
			UpdateEntitlement();
		}

		if (Online::ShouldShowRequestEASignIn())
			EASignInContainer.Visibility = ESlateVisibility::SelfHitTestInvisible;
		else
			EASignInContainer.Visibility = ESlateVisibility::Collapsed;
	}

	void UpdateEntitlement()
	{
		if (PrevEntitlement == EHazeEntitlement::FriendPass)
		{
			FriendsPassContainer.Visibility = ESlateVisibility::Visible;
			FriendsPassInfoButton.Visibility = ESlateVisibility::Visible;
			PurchaseGameButton.Visibility = ESlateVisibility::Visible;

			PlayLocalButton.DemoCallout.Visibility = ESlateVisibility::HitTestInvisible;
			if (Game::PlatformName == "Sage")
				PlayLocalWirelessButton.DemoCallout.Visibility = ESlateVisibility::HitTestInvisible;
			PlayOnlineButton.DemoCallout.Visibility = ESlateVisibility::HitTestInvisible;

			PurchaseGameButton.bIsFirstOption = true;
			PlayLocalButton.bIsFirstOption = false;
		}
		else
		{
			if (FriendsPassInfoButton.bFocused || PurchaseGameButton.bFocused)
				Widget::SetAllPlayerUIFocus(PlayLocalButton);

			FriendsPassContainer.Visibility = ESlateVisibility::Collapsed;
			FriendsPassInfoButton.Visibility = ESlateVisibility::Collapsed;
			PurchaseGameButton.Visibility = ESlateVisibility::Collapsed;

			PlayLocalButton.DemoCallout.Visibility = ESlateVisibility::Collapsed;
			if (Game::PlatformName == "Sage")
				PlayLocalWirelessButton.DemoCallout.Visibility = ESlateVisibility::Collapsed;
			PlayOnlineButton.DemoCallout.Visibility = ESlateVisibility::Collapsed;

			PurchaseGameButton.bIsFirstOption = false;
			PlayLocalButton.bIsFirstOption = true;
		}
	}

	UFUNCTION()
	private void OnPlayLocal(UMenuButtonWidget Button)
	{
		Lobby::Menu_CreateLocalLobby(MainMenu.OwnerIdentity);
	}

	UFUNCTION()
	private void OnPlayLocalWireless(UMenuButtonWidget Button)
	{
		if (Online::OnlinePlatformName == "Sage")
		{
			FMessageDialogOption HostLanOption;
			HostLanOption.OnChosen = FOnMessageDialogOptionChosen(this, n"OnHostNintendoLobby");
			HostLanOption.Label = NSLOCTEXT("HostLobby", "HostLobbyLan", "Host through Local Wireless");
			HostLanOption.DescriptionText = NSLOCTEXT("HostLobby", "HostLobbyNintendo_Description", "Host a game through local wireless.\n\nOnly friends playing Split Fiction on\nNintendo Switch™ 2 can join the game.");

			FMessageDialogOption FindJoinLanOption;
			FindJoinLanOption.OnChosen = FOnMessageDialogOptionChosen(this, n"OnFindJoinNintendoLobby");
			FindJoinLanOption.Label = NSLOCTEXT("HostLobby", "FindLobbyLan", "Find and Join through Local Wireless");
			FindJoinLanOption.DescriptionText = NSLOCTEXT("HostLobby", "FindJoinLobbyNintendo_Description", "Find and Join a game through local wireless.");

			FMessageDialogOption PolestarOption;
			PolestarOption.OnChosen = FOnMessageDialogOptionChosen(this, n"OnHostPolestar");
			PolestarOption.Label = NSLOCTEXT("HostLobby", "HostLobbyPolestar", "Host a game using GameShare");
			PolestarOption.DescriptionText = NSLOCTEXT("HostLobby", "HostLobbyPolestar_Description", "Host a game using GameShare");

			FMessageDialog Dialog;
			Dialog.AddOption(HostLanOption);
			Dialog.AddOption(FindJoinLanOption);
			Dialog.AddOption(PolestarOption);
			Dialog.AddCancelOption(FOnMessageDialogOptionChosen(this, n"OnCancelLocalWireless"));
			ShowPopupMessage(Dialog, this);
		}
	}

	UFUNCTION()
	private void OnCancelLocalWireless()
	{
		Widget::SetAllPlayerUIFocus(PlayLocalWirelessButton);
	}

	UFUNCTION()
	private void OnPlayOnline(UMenuButtonWidget Button)
	{
		if (Online::OnlinePlatformName == "Steam")
		{
			// On steam, we can host lobbies either using Steam or EA servers
			FMessageDialogOption HostSteamOption;
			HostSteamOption.OnChosen = FOnMessageDialogOptionChosen(this, n"OnHostSteamLobby");
			HostSteamOption.Label = NSLOCTEXT("HostLobby", "HostLobbySteam", "Host through Steam");
			HostSteamOption.DescriptionText = NSLOCTEXT("HostLobby", "HostLobbySteam_Description", "Host a game through Steam servers.\n\nOnly friends playing Split Fiction on Steam can join the game.");

			FMessageDialogOption HostEAOption;
			HostEAOption.OnChosen = FOnMessageDialogOptionChosen(this, n"OnHostEALobby");
			HostEAOption.Label = NSLOCTEXT("HostLobby", "HostLobbyEA", "Host on EA Servers");
			HostEAOption.DescriptionText = NSLOCTEXT("HostLobby", "HostLobbyEA_Description", "Host a game on EA servers.\n\nFriends playing Split Fiction on Steam, the EA App, or consoles will be able to join the game for cross-play.\n\nBoth players must be signed in to an EA Account to play on EA servers.");
			
			FMessageDialog Dialog;
			Dialog.AddOption(HostSteamOption);
			Dialog.AddOption(HostEAOption);
			Dialog.AddCancelOption(FOnMessageDialogOptionChosen(this, n"OnCancelHost"));
			ShowPopupMessage(Dialog, this);
		}
		else
		{
			OnHostEALobby();
		}
	}

	UFUNCTION()
	private void OnCancelHost()
	{
		Widget::SetAllPlayerUIFocus(PlayOnlineButton);
	}

	UFUNCTION()
	private void OnHostEALobby()
	{
		Online::SetGameServerMode(EHazeGameServerMode::Default);
		Lobby::Menu_CreateHostLobby(MainMenu.OwnerIdentity);
	}

	UFUNCTION()
	private void OnHostSteamLobby()
	{
		Online::SetGameServerMode(EHazeGameServerMode::UseSteamGameServers);
		Lobby::Menu_CreateHostLobby(MainMenu.OwnerIdentity);
	}
	
	UFUNCTION()
	private void OnHostNintendoLobby()
	{
		Online::SetGameServerMode(EHazeGameServerMode::UseNintendoGameServers);
		Lobby::Menu_CreateHostLobby(MainMenu.OwnerIdentity);
	}

	UFUNCTION()
	private void OnFindJoinNintendoLobby()
	{
		Online::SetGameServerMode(EHazeGameServerMode::UseNintendoGameServers);
		MainMenu.GotoLocalWireless();
	}

	UFUNCTION()
	private void OnHostPolestar()
	{
		Online::SetGameServerMode(EHazeGameServerMode::UseNintendoGameServers);
		Lobby::Menu_CreateLocalLobby(MainMenu.OwnerIdentity);
	}

	UFUNCTION()
	private void OnPromptJoin(UMenuButtonWidget Button)
	{
		Online::PromptForJoin(MainMenu.OwnerIdentity);
	}

	UFUNCTION()
	private void OnDevJoin(UMenuButtonWidget Button)
	{
		Online::PromptForJoin(MainMenu.OwnerIdentity);
	}

	UFUNCTION()
	private void OnDevMenu(UMenuButtonWidget Button)
	{
		DevMenu::OpenDevMenuOverlay();
	}

	UFUNCTION()
	private void OnOptions(UMenuButtonWidget Button)
	{
		MainMenu.ShowOptionsMenu();
	}

	UFUNCTION()
	private void OnAccessibility(UMenuButtonWidget Button)
	{
		MainMenu.ShowOptionsMenu();

		auto OptionsState = Cast<UMainMenuOptions>(MainMenu.ActiveWidget);
		if (OptionsState != nullptr)
			OptionsState.OptionsMenu.SwitchToPage(3);
	}

	UFUNCTION()
	private void OnCredits(UMenuButtonWidget Button)
	{
		MainMenu.ShowCredits();
	}

	UFUNCTION()
	private void OnQuit(UMenuButtonWidget Button)
	{
		Game::QuitGame();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDown(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		return FEventReply::Handled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonUp(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		return FEventReply::Handled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry MyGeometry, FFocusEvent InFocusEvent)
	{
		return FEventReply::Handled().SetUserFocus(PlayLocalButton, InFocusEvent.Cause);
	}
};