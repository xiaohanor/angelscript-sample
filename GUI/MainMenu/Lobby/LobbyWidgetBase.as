
class ULobbyWidgetBase : UMainMenuStateWidget
{
	UHazeLobby Lobby;

	void OnTransitionEnter(EMainMenuState PreviousState, bool bSnap) override
	{
		Super::OnTransitionEnter(PreviousState, bSnap);

		Lobby = Lobby::GetLobby();
	}

	FText GetLobbyNetworkTypeText() const
	{
		if (Lobby == nullptr)
			return FText();
		else if (Lobby.Network == EHazeLobbyNetwork::Local)
			return NSLOCTEXT("Lobby", "PlayLocalHeading", "Play Local");
		else if (Online::OnlinePlatformName == "Sage" && Online::GetGameServerMode() == EHazeGameServerMode::UseNintendoGameServers)
			return NSLOCTEXT("Lobby", "PlayLocalWirelessHeading", "Play Local Wireless");
		else
			return NSLOCTEXT("Lobby", "PlayOnlineHeading", "Play Online");
	}

	FText GetLobbyStartTypeText() const
	{
		if (Lobby == nullptr)
			return FText();

		switch (Lobby.StartType)
		{
			case EHazeLobbyStartType::Continue:
				return NSLOCTEXT("Lobby", "ContinueHeading", "Continue");
			case EHazeLobbyStartType::NewGame:
				return NSLOCTEXT("Lobby", "NewGameHeading", "New Game");
			case EHazeLobbyStartType::ChapterSelect:
				return NSLOCTEXT("Lobby", "ChapterSelectHeading", "Chapter Select");
			default:
				break;
		}

		return FText();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		Super::Tick(MyGeometry, InDeltaTime);

		if (!bIsActive)
			return;
		if (!IsValid(MainMenu))
			return;

		// If the guest leaves, go back to the players screen
		if (Lobby.NumIdentitiesInLobby() != 2 && Lobby.LobbyOwner.IsLocal() && Lobby.LobbyState != EHazeLobbyState::LobbyPlayers)
		{
			Lobby::Menu_LobbySetState(EHazeLobbyState::LobbyPlayers);
			MainMenu.GotoLobbyPlayers();
			return;
		}

		// Make sure the right lobby state is visible at all times
		switch (Lobby.LobbyState)
		{
			case EHazeLobbyState::LobbyPlayers:
				MainMenu.GotoLobbyPlayers();
			break;
			case EHazeLobbyState::ChooseStartType:
				MainMenu.GotoLobbyChooseStartType();
			break;
			case EHazeLobbyState::ChapterSelect:
				MainMenu.GotoChapterSelect();
			break;
			case EHazeLobbyState::CharacterSelect:
				MainMenu.GotoCharacterSelect();
			break;
			default:
			break;
		}
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry Geom, FKeyEvent Event)
	{
		// If the console is up, don't eat the key input
		if (Console::IsConsoleActive() || Console::IsConsoleKey(Event.Key))
			return FEventReply::Unhandled();
		if (Lobby == nullptr || Lobby.HasGameStarted())
			return FEventReply::Unhandled();
		if (Event.IsRepeat())
			return FEventReply::Unhandled();
		if (!bIsActive)
			return FEventReply::Handled();

		UHazePlayerIdentity KeyIdentity = Online::GetLocalIdentityAssociatedWithInputDevice(Event.InputDeviceId);
		UHazePlayerIdentity KeyIdentityInLobby = Lobby.GetIdentityForInput(Event.InputDeviceId);

		if (Event.Key == EKeys::Escape || Event.Key == EKeys::Virtual_Back)
		{
			// A guest player is always allowed to leave the lobby, even if they can't control it
			if (MainMenu.OwnerIdentity.TakesInputFromController(Event.InputDeviceId))
			{
				if (!Lobby.LobbyOwner.IsLocal())
				{
					LeaveLobby();
					return FEventReply::Handled();
				}
			}
		}

		return Super::OnKeyDown(Geom, Event);
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnAnalogValueChanged(FGeometry MyGeometry, FAnalogInputEvent InAnalogInputEvent)
	{
		if (InAnalogInputEvent.GetKey() == EKeys::Gamepad_RightY)
		{
			UAccessibilityChatWidget ChatWidget = UAccessibilityTextToSpeechSubsystem::Get().SpeechToTextChatWidget;
			if (ChatWidget != nullptr)
			{
				if (ChatWidget.BrowseInput(InAnalogInputEvent))
					return FEventReply::Handled();
			}
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION()
	void LeaveLobby(UHazeUserWidget Widget = nullptr)
	{
		if (Lobby.Network == EHazeLobbyNetwork::Local)
		{
			// Just leave immediately for local lobbies, not a big deal
			Lobby::Menu_LeaveLobby();
		}
		else
		{
			// Confirm for disconnecting from online lobby
			FMessageDialog Dialog;
			Dialog.Message = NSLOCTEXT("Lobby", "LeavyLobbyQuestion", "Disconnect from the online lobby?");
			Dialog.AddOption(NSLOCTEXT("Lobby", "ConfirmLeaveLobby", "Disconnect"), FOnMessageDialogOptionChosen(this, n"Confirm_LeaveLobby"));
			Dialog.AddCancelOption(FOnMessageDialogOptionChosen());

			ShowPopupMessage(Dialog, this);
		}
	}

	UFUNCTION()
	void Confirm_LeaveLobby()
	{
		Lobby::Menu_LeaveLobby();
	}

	UFUNCTION(BlueprintPure)
	bool IsTrialMode()
	{
		if (Online::GetGameEntitlement() == EHazeEntitlement::FullGame)
			return false;

		auto HazeGameInstance = Game::GetHazeGameInstance();
		if (HazeGameInstance == nullptr)
			return false;
		if (HazeGameInstance.bRemoteEntitlementSynced && HazeGameInstance.RemoteEntitlement == EHazeEntitlement::FullGame)
			return false;

		return true;
	}

	UFUNCTION(BlueprintPure)
	bool ShouldShowFullGameIndicator()
	{
		// If this is a trial lobby, show that
		if (IsTrialMode())
			return false;

		// If we are friend's pass in a full game lobby, show it
		if (Online::GetGameEntitlement() == EHazeEntitlement::FriendPass)
			return true;

		// Don't need to show full game to someone who owns the game
		return false;
	}

};