const FConsoleVariable CVar_AlwaysShowFriendsPassPopup("Haze.AlwaysShowFriendsPassPopup", 0);

namespace Lobby
{
	const FConsoleVariable CVar_UsePlaystationLobbyIcons("Haze.UsePlaystationLobbyIcons", 0);
}

class ULobbyPlayersWidget : ULobbyWidgetBase
{
	default bShowMenuBackground = true;
	default bShowButtonBarBackground = true;

	UPROPERTY(BindWidget)
	UWidget UIRoot;
	UPROPERTY(BindWidget)
	UWidget CrossplayWarning;

	UPROPERTY(BindWidget)
	UMenuPromptOrButton BackButton;
	UPROPERTY(BindWidget)
	UMenuPromptOrButton InviteButton;
	UPROPERTY(BindWidget)
	UMenuPromptOrButton ProceedButton;
	UPROPERTY(BindWidget)
	UMenuPromptOrButton FriendsPassInfoButton;

	UPROPERTY(BindWidget)
	ULobbyPlayerInfo PlayerOneInfo;
	UPROPERTY(BindWidget)
	ULobbyPlayerInfo PlayerTwoInfo;

	UHazePlayerIdentity PendingJoinIdentity;
	bool bIsPendingSignIn = false;
	bool bInviteButtonPressed = false;

	float EngagementGraceTimer = 0.0;
	float FriendsPassInfoTimer = 0.0;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		PlayerOneInfo.OnClicked.AddUFunction(this, n"OnClickedPlayerInfo");
		PlayerTwoInfo.OnClicked.AddUFunction(this, n"OnClickedPlayerInfo");

		ProceedButton.OnPressed.AddUFunction(this, n"ProceedToNext");
		InviteButton.OnPressed.AddUFunction(this, n"InviteFriend");
		BackButton.OnPressed.AddUFunction(this, n"LeaveLobby");
		FriendsPassInfoButton.OnPressed.AddUFunction(this, n"OnClickedFriendsPassInfoButton");
	}

	void OnTransitionEnter(EMainMenuState PreviousState, bool bSnap) override
	{
		Super::OnTransitionEnter(PreviousState, bSnap);

		MenuBackgroundTitle = GetLobbyNetworkTypeText();

		// Unselect a character if we have any selected
		for (auto& Member : Lobby.LobbyMembers)
		{
			if (Member.Identity != nullptr && Member.Identity.IsLocal()
				&& Member.ChosenPlayer != EHazePlayer::MAX)
			{
				Lobby::Menu_LobbySetReady(Member.Identity, false);
				Lobby::Menu_LobbySelectPlayer(Member.Identity, EHazePlayer::MAX);
			}
		}

		// Show friends pass popup if it's the first time we've gone online
		if (ShouldShowFriendsPassInfo())
		{
			FString ShownValue;
			if (!Profile::GetProfileValue(Lobby.LobbyOwner, n"FriendsPassInfoShown", ShownValue)
				|| ShownValue != "True" || CVar_AlwaysShowFriendsPassPopup.GetInt() != 0)
			{
				FriendsPassInfoTimer = 0.5;
			}

			FriendsPassInfoButton.Visibility = ESlateVisibility::Visible;
		}
		else
		{
			FriendsPassInfoButton.Visibility = ESlateVisibility::Collapsed;
		}

		if (Lobby.Network != EHazeLobbyNetwork::Local)
		{
			BackButton.Text = NSLOCTEXT("MainMenuLobby", "DisconnectLobby", "Disconnect");
			BackButton.UpdateWidgets();
		}

		UpdateWidgetState();
		NarrateFullMenu();
	}

	void UpdateWidgetState()
	{
		if (CanProceedToNext())
			ProceedButton.bDisabled = false;
		else
			ProceedButton.bDisabled = true;

		if (Lobby != nullptr && Lobby.Network == EHazeLobbyNetwork::Host
			// On nintendo, when we host a local wireless lobby we cannot invite players and they can only join after direct search
			&& Online::GetGameServerMode() != EHazeGameServerMode::UseNintendoGameServers)
		{
			InviteButton.Visibility = ESlateVisibility::Visible;
			if (Lobby.NumIdentitiesInLobby() >= 2)
				InviteButton.bDisabled = true;
			else
				InviteButton.bDisabled = false;
		}
		else
		{
			InviteButton.Visibility = ESlateVisibility::Collapsed;
		}

		PlayerOneInfo.Update(Lobby.LobbyMembers[0], false, Lobby.Network != EHazeLobbyNetwork::Local);
		PlayerTwoInfo.Update(Lobby.LobbyMembers[1], IsJoinInProgress(), Lobby.Network != EHazeLobbyNetwork::Local);

		if (Online::OnlinePlatformName == "XSX" && Online::IsCrossplayActive())
		{
			// On xbox, we must show a warning when a lobby contains cross platform players
			CrossplayWarning.Visibility = ESlateVisibility::HitTestInvisible;
		}
		else
		{
			CrossplayWarning.Visibility = ESlateVisibility::Hidden;
		}
	}

	UFUNCTION(BlueprintPure)
	bool CanInvitePlayer()
	{
		if (Lobby == nullptr)
			return false;
		return Lobby.Network == EHazeLobbyNetwork::Host
			// On nintendo, when we host a local wireless lobby we cannot invite players and they can only join after direct search
			&& Online::GetGameServerMode() != EHazeGameServerMode::UseNintendoGameServers
			&& Lobby.NumIdentitiesInLobby() < 2;
	}

	UFUNCTION()
	void InviteFriend(UHazeUserWidget Widget = nullptr)
	{
		if (!Online::IsCrossplayEnabled()
			|| Online::GetGameServerMode() == EHazeGameServerMode::UseSteamGameServers)
		{
			OnInviteFirstParty();
			return;
		}
		else if (Online::OnlinePlatformName == "Steam" && Online::GetGameServerMode() == EHazeGameServerMode::Default)
		{
			// On steam, a lobby with Default game server mode is an EA lobby, so just go to EA Friends directly,
			// we already made the choice to do crossplay when we hosted the lobby
			OnOpenEAFriends();
			return;
		}
		else if (Online::OnlinePlatformName == "Origin")
		{
			// Origin always goes directly to EA friends, the overlay doesn't function very well
			OnOpenEAFriends();
			return;
		}

		FMessageDialogOption FirstPartyOption;
		FirstPartyOption.OnChosen = FOnMessageDialogOptionChosen(this, n"OnInviteFirstParty");
		if (Online::OnlinePlatformName == "Steam" || Online::OnlinePlatformName == "Editor")
		{
			FirstPartyOption.Label = NSLOCTEXT("LobbyPlayers", "InviteSteam", "Invite Friend through Steam");
			FirstPartyOption.DescriptionText = NSLOCTEXT("LobbyPlayers", "InviteSteam_Description", "Send a game invite to a friend on your Steam friends list");
		}
		// else if (Online::OnlinePlatformName == "PC" || Online::OnlinePlatformName == "Origin")
		// {
		// 	FirstPartyOption.Label = NSLOCTEXT("LobbyPlayers", "InviteEAApp", "Invite Friend through EA app");
		// 	FirstPartyOption.DescriptionText = NSLOCTEXT("LobbyPlayers", "InviteEAApp_Description", "Send a game invite to a friend playing on the EA app");
		// }
		else if (Online::OnlinePlatformName == "PS5")
		{
			FirstPartyOption.Label = NSLOCTEXT("LobbyPlayers", "InvitePlaystation", "Invite Friend through PlayStation™Network");
			FirstPartyOption.DescriptionText = NSLOCTEXT("LobbyPlayers", "InvitePlaystation_Description", "Send a game invite to a friend playing on a PlayStation®5 console");
		}
		else if (Online::OnlinePlatformName == "XSX")
		{
			FirstPartyOption.Label = NSLOCTEXT("LobbyPlayers", "InviteXbox", "Invite Friend through Xbox Network");
			FirstPartyOption.DescriptionText = NSLOCTEXT("LobbyPlayers", "InviteXbox_Description", "Send a game invite to a friend playing on Xbox");
		}
		else if (Online::OnlinePlatformName == "Sage")
		{
			FirstPartyOption.Label = NSLOCTEXT("LobbyPlayers", "InviteNintendo", "Invite Friend");
			FirstPartyOption.DescriptionText = NSLOCTEXT("LobbyPlayers", "InviteNintendo_Description", "Send a game invite to a friend playing on Nintendo Switch™ 2");
		}
		
		FMessageDialogOption EAFriendsOption;
		EAFriendsOption.OnChosen = FOnMessageDialogOptionChosen(this, n"OnOpenEAFriends");
		EAFriendsOption.Label = NSLOCTEXT("LobbyPlayers", "InviteEAFriends", "EA Friends List");
		if (Online::OnlinePlatformName == "Sage")
		{
			// Nintendo needs different localizations for these terms
			EAFriendsOption.DescriptionText = NSLOCTEXT("LobbyPlayers", "InviteEAFriends_Description_Sage", "Manage your EA friends list and send invites to friends playing on any platform");
		}
		else
		{
			EAFriendsOption.DescriptionText = NSLOCTEXT("LobbyPlayers", "InviteEAFriends_Description", "Manage your EA friends list and send invites to friends playing on any platform");
		}
		
		FMessageDialog Dialog;
		Dialog.AddOption(FirstPartyOption);
		Dialog.AddOption(EAFriendsOption);
		Dialog.AddCancelOption();
		ShowPopupMessage(Dialog, this);
	}

	UFUNCTION()
	private void OnClickedFriendsPassInfoButton(UHazeUserWidget Widget)
	{
		ShowFriendsPassPopup();
	}

	UFUNCTION()
	private void OnOpenEAFriends()
	{
		MainMenu.GotoLobbyCrossplay();
	}

	UFUNCTION()
	private void OnInviteFirstParty()
	{
		if (CanInvitePlayer())
			Online::PromptForInvite();
	}

	UFUNCTION()
	void ProceedToNext(UHazeUserWidget Widget = nullptr)
	{
		if (CanProceedToNext())
			Lobby::Menu_LobbySetState(EHazeLobbyState::ChooseStartType);
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

		if (Event.Key == EKeys::F2 || Event.Key == EKeys::Gamepad_FaceButton_Left)
		{
			if (ShouldShowFriendsPassInfo())
			{
				ShowFriendsPassPopup();
				return FEventReply::Handled();
			}
		}

		// Host can prompt to invite a player
		if (Event.Key == EKeys::Gamepad_FaceButton_Top
			|| Event.Key == EKeys::Y
			|| Event.Key == EKeys::F1)
		{
			bInviteButtonPressed = true;
			return FEventReply::Handled();
		}

		if (Lobby.NumIdentitiesInLobby() < 2
			&& Lobby.Network == EHazeLobbyNetwork::Local
			&& PendingJoinIdentity == nullptr
			&& (KeyIdentityInLobby == nullptr || KeyIdentityInLobby.IsSecondaryController(Event.InputDeviceId))
		)
		{
			if (Event.Key == EKeys::Virtual_Accept || Event.Key == EKeys::Enter)
			{
				// Join a local lobby
				PendingJoinIdentity = KeyIdentity;
				if (KeyIdentityInLobby == nullptr)
					KeyIdentity.OnInputTakenFromController(Event.InputDeviceId, true);
				ProceedPendingJoin();
				return FEventReply::Handled();
			}
		}

		if (Event.Key == EKeys::Escape || Event.Key == EKeys::Virtual_Back)
		{
			// Leave lobby for local joined player
			if (KeyIdentityInLobby != nullptr && CanIdentityLeaveLobby(KeyIdentityInLobby) && Lobby.Network == EHazeLobbyNetwork::Local)
			{
				Lobby::Menu_RemoveLocalPlayerFromLobby(KeyIdentityInLobby);
				return FEventReply::Handled();
			}

			// Leave lobby for owner of menu, could be leaving a joined online lobby or a local lobby
			if (MainMenu.OwnerIdentity.TakesInputFromController(Event.InputDeviceId))
			{
				LeaveLobby();
				return FEventReply::Handled();
			}
		}

		// Proceed to character select from chapter select
		if (Event.Key == EKeys::Enter
			|| Event.Key == EKeys::Virtual_Accept)
		{
			if (Lobby.LobbyOwner.TakesInputFromController(Event.InputDeviceId)
				&& Lobby.NumIdentitiesInLobby() >= 2)
			{
				ProceedToNext();
				return FEventReply::Handled();
			}
		}

		return Super::OnKeyDown(Geom, Event);
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyUp(FGeometry Geom, FKeyEvent Event)
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

		// Host can prompt to invite a player
		if (Event.Key == EKeys::Gamepad_FaceButton_Top
			|| Event.Key == EKeys::Y
			|| Event.Key == EKeys::F1)
		{
			if (bInviteButtonPressed)
			{
				bInviteButtonPressed = false;
				if (CanInvitePlayer())
					InviteFriend();
			}
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION()
	private void OnClickedPlayerInfo()
	{
		UHazePlayerIdentity KeyIdentity = Online::GetLocalIdentityAssociatedWithInputDevice(Online::KeyboardInputDevice);
		UHazePlayerIdentity KeyIdentityInLobby = Lobby.GetIdentityForInput(Online::KeyboardInputDevice);

		if (Lobby.NumIdentitiesInLobby() < 2
			&& Lobby.Network == EHazeLobbyNetwork::Local
			&& PendingJoinIdentity == nullptr
			&& (KeyIdentityInLobby == nullptr || KeyIdentityInLobby.IsSecondaryController(Online::KeyboardInputDevice))
		)
		{
			// Join a local lobby
			PendingJoinIdentity = KeyIdentity;
			if (KeyIdentityInLobby == nullptr)
				KeyIdentity.OnInputTakenFromController(Online::KeyboardInputDevice, true);
			ProceedPendingJoin();
		}
	}

	void ProceedPendingJoin()
	{
		if (Lobby.NumIdentitiesInLobby() >= 2)
		{
			PendingJoinIdentity = nullptr;
			return;
		}

		// Make sure we're signed in before we can join
		if (!Online::IsIdentitySignedIn(PendingJoinIdentity) || Lobby.IsMember(PendingJoinIdentity))
		{
			auto SignInWithIdentity = PendingJoinIdentity;
			PendingJoinIdentity = nullptr;
			bIsPendingSignIn = true;
			Online::PromptIdentitySignIn(SignInWithIdentity, false, FHazeOnOnlineIdentitySignedIn(this, n"OnJoinIdentitySignedIn"));
			return;
		}

		// Make sure the profile is loaded before we can join
		if (!Profile::IsProfileLoaded(PendingJoinIdentity))
		{
			Profile::LoadProfile(PendingJoinIdentity, FHazeOnProfileLoaded(this, n"OnJoinIdentityProfileLoaded"));
			return;
		}

		// All steps completed!
		auto FinishedIdentity = PendingJoinIdentity;
		PendingJoinIdentity = nullptr;
		EngagementGraceTimer = 1.0;
		Lobby::Menu_AddLocalIdentityToLobby(FinishedIdentity);
	}

	UFUNCTION()
	void OnJoinIdentityProfileLoaded(UHazePlayerIdentity Identity)
	{
		ProceedPendingJoin();
	}

	UFUNCTION()
	void OnJoinIdentitySignedIn(UHazePlayerIdentity Identity, bool bSuccess)
	{
		bIsPendingSignIn = false;
		if (bSuccess && PendingJoinIdentity == nullptr && !Lobby.IsMember(Identity))
		{
			PendingJoinIdentity = Identity;
			ProceedPendingJoin();
		}
	}

	UFUNCTION(BlueprintPure)
	bool CanProceedToNext()
	{
		if (Lobby == nullptr)
			return false;
		return Lobby.LobbyOwner.IsLocal()
			&& Lobby.NumIdentitiesInLobby() >= 2;
	}

	UFUNCTION(BlueprintPure)
	bool IsJoinInProgress()
	{
		return PendingJoinIdentity != nullptr || bIsPendingSignIn;
	}

	bool CanIdentityLeaveLobby(UHazePlayerIdentity Identity)
	{
		if (Identity == Lobby.LobbyMembers[1].Identity)
		{
			// Secondary player can always leave
			return true;
		}

		if (Identity == Lobby.LobbyMembers[0].Identity)
		{
			// Primary player can only leave on desktop platforms
			if (!Game::IsConsoleBuild())
				return true;
			else
				return false;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geom, float DeltaTime)
	{
		Super::Tick(Geom, DeltaTime);

		if (Lobby == nullptr)
			return;

		if (FriendsPassInfoTimer > 0.0)
		{
			FriendsPassInfoTimer -= DeltaTime;
			if (FriendsPassInfoTimer <= 0.0)
			{
				ShowFriendsPassPopup();
				Profile::SetProfileValue(Lobby.LobbyOwner, n"FriendsPassInfoShown", "True");
			}
		}

		// If the secondary identity is disengaged, remove it from the lobby
		EngagementGraceTimer -= DeltaTime;
		if (EngagementGraceTimer <= 0.0)
		{
			for (auto& Member : Lobby.LobbyMembers)
			{
				if (Member.Identity != nullptr && Member.Identity != Online::PrimaryIdentity)
				{
					if (Member.Identity.Engagement != EHazeIdentityEngagement::Engaged)
					{
						//GetAudioManager().UI_OnSelectionCancel();
						Lobby::Menu_RemoveLocalPlayerFromLobby(Member.Identity);
					}
				}
			}
		}

		UpdateWidgetState();
	}

	UFUNCTION(BlueprintPure)
	bool ShouldShowFriendsPassInfo()
	{
		if (Online::GetGameEntitlement() == EHazeEntitlement::FriendPass)
			return false;
		if (Lobby == nullptr)
			return false;
		if (Lobby.Network != EHazeLobbyNetwork::Host)
			return false;
		if (!Lobby.LobbyOwner.IsLocal())
			return false;
		return true;
	}

	UFUNCTION()
	void ShowFriendsPassPopup()
	{
		FMessageDialogOption ProceedOption;
		ProceedOption.Label = NSLOCTEXT("FriendsPassInfo", "ContinueToGame", "Continue to Game");
		ProceedOption.Type = EMessageDialogOptionType::Cancel;

		FMessageDialogOption MoreInfoOption;
		MoreInfoOption.Label = NSLOCTEXT("FriendsPassInfo", "LearnMore", "Learn More Online");
		MoreInfoOption.OnChosen = FOnMessageDialogOptionChosen(this, n"ShowFriendsPassMoreInfo");

		FMessageDialog Dialog;
		if (Online::OnlinePlatformName == "Sage")
		{
			// Nintendo needs different localizations for these terms
			Dialog.Message = NSLOCTEXT("FriendsPassInfo", "PopupMessage_Sage", "Split Fiction has a Friend's Pass available!\n\nInvite your friends to join online co-op for free by using the Friend's Pass.");
		}
		else
		{
			Dialog.Message = NSLOCTEXT("FriendsPassInfo", "PopupMessage", "Split Fiction has a Friend's Pass available!\n\nInvite your friends to join online co-op for free by using the Friend's Pass.");
		}
		Dialog.AddOption(ProceedOption);
		Dialog.AddOption(MoreInfoOption);
		ShowPopupMessage(Dialog, this);
	}

	UFUNCTION()
	void ShowFriendsPassMoreInfo()
	{
		Online::ShowFriendsPassInfo();
	}

	private void NarrateFullMenu()
	{
		if (Game::IsNarrationEnabled())
		{
			FString NarrateString = MenuBackgroundTitle.ToString();

			EHazePlayerControllerType Controller = Lobby::GetMostLikelyControllerType();
			if (Lobby.Network == EHazeLobbyNetwork::Local)
			{
				const bool bIsDesktop = !Game::IsConsoleBuild();

				NarrateString += ", Join";
				if (Controller != EHazePlayerControllerType::Keyboard)
				{
					NarrateString += ", " + Game::KeyToNarrationText(EKeys::Virtual_Accept, Controller).ToString();
				}
				else if (bIsDesktop)
				{
					NarrateString += ", " + Game::KeyToNarrationText(EKeys::Virtual_Accept, EHazePlayerControllerType::Xbox).ToString();
				}

				if (bIsDesktop)
				{
					NarrateString += " or enter key";
				}
			}

			if (Controller != EHazePlayerControllerType::Keyboard)
			{
				NarrateString += ", " + BackButton.Text.ToString();
				NarrateString += ", " + Game::KeyToNarrationText(EKeys::Virtual_Back, Controller).ToString();

				if (InviteButton.Visibility == ESlateVisibility::Visible && InviteButton.bDisabled == false)
				{
					NarrateString += ", " + InviteButton.Text.ToString();
					NarrateString += ", " + Game::KeyToNarrationText(EKeys::Gamepad_FaceButton_Top, Controller).ToString();
				}

				NarrateString += ", " + ProceedButton.Text.ToString();
				NarrateString += ", " + Game::KeyToNarrationText(EKeys::Virtual_Accept, Controller).ToString();
			}

			Game::NarrateString(NarrateString);
		}
	}
};

enum ELobbyPlayerWidgetState
{
	Waiting,
	IsBusy,
	Ready,
}

event void FOnLobbyPlayerWidgetStateUpdated(ELobbyPlayerWidgetState State);

class ULobbyPlayerInfo : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UTextBlock PlayerNameText;
	UPROPERTY(BindWidget)
	UImage ControllerImage;

	UPROPERTY(BindWidget)
	UWidget LoadingSpinner;
	UPROPERTY(BindWidget)
	UWidget ActiveHighlight;
	UPROPERTY(BindWidget)
	UWidget TopBar;

	UPROPERTY(BindWidget)
	UWidget JoinPromptContainer;
	UPROPERTY(BindWidget)
	UHazeInputButton JoinPromptIcon;
	UPROPERTY(BindWidget)
	UWidget JoinPromptSeparator;
	UPROPERTY(BindWidget)
	UHazeInputButton JoinPromptKeyboardIcon;

	UPROPERTY(EditAnywhere)
	FText DefaultText;

	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_DualShock;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_DualSense;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_Generic;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_Xbox;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_Sage_Pro;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_Sage_DualJoycon;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_Sage_Handheld;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_Keyboard;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_Remote;

	UPROPERTY(BindWidget)
	UImage PlayerPlatformIcon;

	UPROPERTY()
	UTexture2D EAIcon;
	UPROPERTY()
	UTexture2D PlaystationIcon;
	UPROPERTY()
	UTexture2D XboxIcon;
	UPROPERTY()
	UTexture2D SageIcon;

	FOnButtonClickedEvent OnClicked;

	// Purely for ui audio.
	ELobbyPlayerWidgetState WidgetState;
	FOnLobbyPlayerWidgetStateUpdated OnStateUpdated;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		if (Game::IsConsoleBuild())
		{
			JoinPromptSeparator.SetVisibility(ESlateVisibility::Collapsed);
			JoinPromptKeyboardIcon.SetVisibility(ESlateVisibility::Collapsed);
		}
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDown(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.GetEffectingButton() == EKeys::LeftMouseButton)
		{
			OnClicked.Broadcast();
			return FEventReply::Handled();
		}
		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonUp(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.GetEffectingButton() == EKeys::LeftMouseButton)
			return FEventReply::Handled();
		return FEventReply::Unhandled();
	}

	void Update(FHazeLobbyMember Member, bool bIsBusy, bool bIsNetworked)
	{
		auto NewState = ELobbyPlayerWidgetState::Waiting;

		if (bIsBusy)
		{
			PlayerNameText.SetText(DefaultText);
			LoadingSpinner.SetVisibility(ESlateVisibility::HitTestInvisible);

			ControllerImage.SetVisibility(ESlateVisibility::Hidden);
			JoinPromptContainer.SetVisibility(ESlateVisibility::Hidden);

			ActiveHighlight.Visibility = ESlateVisibility::Hidden;
			TopBar.Visibility = ESlateVisibility::Hidden;

			NewState = ELobbyPlayerWidgetState::IsBusy;
		}
		else if (Member.Identity != nullptr)
		{
			FText PlayerName;
			if (!Member.Identity.IsLocal())
				PlayerName = Online::GetRemotePlayerName();
			if (PlayerName.IsEmpty())
				PlayerName = Member.Identity.PlayerName;

			FString PlayerNameStr = PlayerName.ToString();
			if (PlayerNameStr.Len() > 16)
			{
				PlayerNameStr = PlayerNameStr.Mid(0, 16) + "...";
				PlayerNameText.SetText(FText::FromString(PlayerNameStr));
			}
			else
			{
				PlayerNameText.SetText(PlayerName);
			}

			ControllerImage.SetVisibility(ESlateVisibility::HitTestInvisible);
			ActiveHighlight.Visibility = ESlateVisibility::HitTestInvisible;
			TopBar.Visibility = ESlateVisibility::HitTestInvisible;

			LoadingSpinner.SetVisibility(ESlateVisibility::Hidden);
			JoinPromptContainer.SetVisibility(ESlateVisibility::Hidden);

			if (Member.Identity.IsLocal())
			{
				if (Game::PlatformName == "PS5" || Lobby::CVar_UsePlaystationLobbyIcons.GetBool())
				{
					ControllerImage.SetBrushFromTexture(ControllerIcon_Generic);
				}
				else
				{
					switch (Member.Identity.GetControllerType())
					{
						case EHazePlayerControllerType::Keyboard:
							ControllerImage.SetBrushFromTexture(ControllerIcon_Keyboard);
						break;
						case EHazePlayerControllerType::None:
						case EHazePlayerControllerType::Xbox:
							ControllerImage.SetBrushFromTexture(ControllerIcon_Xbox);
						break;
						case EHazePlayerControllerType::PS4:
							ControllerImage.SetBrushFromTexture(ControllerIcon_DualShock);
						break;
						case EHazePlayerControllerType::PS5:
							ControllerImage.SetBrushFromTexture(ControllerIcon_DualSense);
						break;
						case EHazePlayerControllerType::Sage_Pro:
							ControllerImage.SetBrushFromTexture(ControllerIcon_Sage_Pro);
						break;
						case EHazePlayerControllerType::Sage_DualJoycon:
							ControllerImage.SetBrushFromTexture(ControllerIcon_Sage_DualJoycon);
						break;
						case EHazePlayerControllerType::Sage_Handheld:
							ControllerImage.SetBrushFromTexture(ControllerIcon_Sage_Handheld);
						break;
					}
				}
			}
			else
			{
				ControllerImage.SetBrushFromTexture(ControllerIcon_Remote);
			}

			NewState = ELobbyPlayerWidgetState::Ready;
		}
		else if (!bIsNetworked)
		{
			PlayerNameText.SetText(DefaultText);
			ActiveHighlight.Visibility = ESlateVisibility::Hidden;
			TopBar.Visibility = ESlateVisibility::Hidden;
			LoadingSpinner.SetVisibility(ESlateVisibility::Hidden);
			ControllerImage.SetVisibility(ESlateVisibility::Hidden);

			JoinPromptContainer.SetVisibility(ESlateVisibility::HitTestInvisible);
			JoinPromptIcon.OverrideControllerType = Lobby::GetMostLikelyControllerType();
			if (JoinPromptIcon.OverrideControllerType == EHazePlayerControllerType::Keyboard)
				JoinPromptIcon.OverrideControllerType = EHazePlayerControllerType::Xbox;

			NewState = ELobbyPlayerWidgetState::Waiting;
		}
		else
		{
			ActiveHighlight.Visibility = ESlateVisibility::Hidden;
			TopBar.Visibility = ESlateVisibility::Hidden;
			PlayerNameText.SetText(DefaultText);
			LoadingSpinner.SetVisibility(ESlateVisibility::Hidden);
			ControllerImage.SetVisibility(ESlateVisibility::Hidden);
			JoinPromptContainer.SetVisibility(ESlateVisibility::Hidden);

			NewState = ELobbyPlayerWidgetState::Waiting;
		}

		if (Member.Identity != nullptr && !Member.Identity.IsLocal() && !bIsBusy)
		{
			if (Game::IsConsoleBuild())
			{
				if (Online::IsRemotePlayerNameEAID())
				{
					PlayerPlatformIcon.Visibility = ESlateVisibility::Visible;
					PlayerPlatformIcon.SetBrushFromTexture(EAIcon);
				}
				else
				{
					PlayerPlatformIcon.Visibility = ESlateVisibility::Visible;
					if (Game::PlatformName == "PS5")
						PlayerPlatformIcon.SetBrushFromTexture(PlaystationIcon);
					else if (Game::PlatformName == "XSX")
						PlayerPlatformIcon.SetBrushFromTexture(XboxIcon);
					else if (Game::PlatformName == "Sage")
						PlayerPlatformIcon.SetBrushFromTexture(SageIcon);
					else
						PlayerPlatformIcon.SetBrushFromTexture(EAIcon);
				}
			}
			else
			{
				if (Online::OnlinePlatformName == "Steam" && Online::IsRemotePlayerNameEAID())
				{
					PlayerPlatformIcon.Visibility = ESlateVisibility::Visible;
					PlayerPlatformIcon.SetBrushFromTexture(EAIcon);
				}
				else
				{
					PlayerPlatformIcon.Visibility = ESlateVisibility::Collapsed;
				}
			}
		}
		else
		{
			PlayerPlatformIcon.Visibility = ESlateVisibility::Collapsed;
		}

		if (NewState != WidgetState)
		{
			WidgetState = NewState;
			OnStateUpdated.Broadcast(WidgetState);
		}
	}
};