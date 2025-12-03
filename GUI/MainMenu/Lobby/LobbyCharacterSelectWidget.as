
const FConsoleVariable CVar_TestNewGameTransition("Haze.TestNewGameTransition", false);

event void FOnCharacterMoveSelection(EHazePlayer Player, bool bMoveLeft);

class ULobbyCharacterSelectWidget : ULobbyWidgetBase
{
	default bCustomNavigation = true;

	UPROPERTY(BindWidget)
	UTextBlock LobbyStartTypeHeading;

	UPROPERTY(BindWidget)
	ULobbyCharacterSelectPlayer PlayerOneInfo;
	UPROPERTY(BindWidget)
	ULobbyCharacterSelectPlayer PlayerTwoInfo;

	bool bWantToStart = false;
	bool bPlayingCutscene = false;

	float StartTimer = 0.0;
	float CurrentOpacity = 1.0;

	FKey KeyboardBoundMoveLeft;
	FKey KeyboardBoundMoveRight;

	FOnCharacterMoveSelection OnCharacterMoveSelection;
	FHazeAcceleratedVector CameraForwardMotion;

	bool CanFadeInState() const override
	{
		return MainMenu.CameraUser.GetActiveLevelSequenceActor() == nullptr;
	}

	FKey GetBoundKey(FName SettingName)
	{
		FKey OutKey;
		bool bSuccess = GameSettings::GetKeybindValue(SettingName, EHazeKeybindType::Keyboard, OutKey);
		if (bSuccess)
			return OutKey;
		return FKey();
	}

	void OnTransitionEnter(EMainMenuState PreviousState, bool bSnap) override
	{
		KeyboardBoundMoveLeft = GetBoundKey(n"MoveLeft");
		KeyboardBoundMoveRight = GetBoundKey(n"MoveRight");

		// Play the opening cutscene if we're starting a new game
		Lobby = Lobby::GetLobby();
		if (Lobby.StartType == EHazeLobbyStartType::NewGame)
		{
			MainMenu.OnPlayOpeningCutscene.Broadcast();
			MainMenu.UpdateChapterSelectMeshVisibility();
			bPlayingCutscene = true;
		}
		else
		{
			bPlayingCutscene = false;
		}

		Super::OnTransitionEnter(PreviousState, bSnap);
		LobbyStartTypeHeading.SetText(GetLobbyStartTypeText());

		// Set the outfits to whatever chapter we're starting
		if (Lobby.StartType != EHazeLobbyStartType::NewGame)
		{
			auto ChapterDatabase = UHazeChapterDatabase::GetChapterDatabase();
			FHazeChapter Chapter = ChapterDatabase.GetChapterByProgressPoint(Lobby.StartChapter);
			FHazeChapterGroup ChapterGroup = ChapterDatabase.GetChapterGroup(Chapter);

			auto MioMesh = Chapter.OverridePlayerVariant_Mio;
			if (MioMesh.IsNull())
				MioMesh = ChapterGroup.PlayerVariant_Mio;

			auto ZoeMesh = Chapter.OverridePlayerVariant_Zoe;
			if (ZoeMesh.IsNull())
				ZoeMesh = ChapterGroup.PlayerVariant_Zoe;

			if (Lobby.StartType == EHazeLobbyStartType::ChapterSelect)
				LobbyStartTypeHeading.SetText(Chapter.Name);
			else
				MainMenu.SetDefaultCharacterMeshVariants();

			MainMenu.SetCharacterMeshVariants(MioMesh, Chapter.OverridePlayerIdleAnimation_Mio, ZoeMesh, Chapter.OverridePlayerIdleAnimation_Zoe);
		}

		auto Camera = MainMenu.StateCameras[int(EMainMenuState::LobbyCharacterSelect)].Camera;
		if (IsValid(Camera))
		{
			Camera.Camera.RelativeLocation = FVector::ZeroVector;
			CameraForwardMotion.SnapTo(FVector::ZeroVector);
		}
	}

	void OnTransitionExit(EMainMenuState NextState, bool bSnap) override
	{
		Game::HazeGameInstance.ClosePauseMenu();

		// If we transition away from the character select screen, stop the cutscene that is playing
		// This is in a loop because stopping a cutscene can start the next one
		while (MainMenu.CameraUser.ActiveLevelSequenceActor != nullptr)
		{
			MainMenu.CameraUser.ActiveLevelSequenceActor.Stop(true);
		}

		Super::OnTransitionExit(NextState, bSnap);

		if (bWantToStart)
		{
			bWantToStart = false;
			if (MainMenu.CameraUser != nullptr)
				MainMenu.CameraUser.FadeInView(0.5);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		PlayerOneInfo.OnClicked.AddUFunction(this, n"OnClickedPlayerOne");
		PlayerOneInfo.LeftArrowButton.OnClicked.AddUFunction(this, n"OnPlayerOneLeft");
		PlayerOneInfo.RightArrowButton.OnClicked.AddUFunction(this, n"OnPlayerOneRight");

		PlayerTwoInfo.OnClicked.AddUFunction(this, n"OnClickedPlayerTwo");
		PlayerTwoInfo.LeftArrowButton.OnClicked.AddUFunction(this, n"OnPlayerTwoLeft");
		PlayerTwoInfo.RightArrowButton.OnClicked.AddUFunction(this, n"OnPlayerTwoRight");
	}

	UFUNCTION()
	private void OnClickedPlayerOne()
	{
		auto& Member = Lobby.LobbyMembers[0];
		if (Member.Identity == nullptr)
			return;
		if (!Member.Identity.TakesInputFromKeyboard())
			return;
		ToggleReady(Online::KeyboardInputDevice);
	}

	UFUNCTION()
	private void OnPlayerOneLeft(UMenuArrowButtonWidget Widget)
	{
		auto& Member = Lobby.LobbyMembers[0];
		if (Member.Identity == nullptr)
			return;
		if (!Member.Identity.TakesInputFromKeyboard())
			return;
		MoveSelection(Online::KeyboardInputDevice, bMoveLeft = true);
	}

	UFUNCTION()
	private void OnPlayerOneRight(UMenuArrowButtonWidget Widget)
	{
		auto& Member = Lobby.LobbyMembers[0];
		if (Member.Identity == nullptr)
			return;
		if (!Member.Identity.TakesInputFromKeyboard())
			return;
		MoveSelection(Online::KeyboardInputDevice, bMoveLeft = false);
	}

	UFUNCTION()
	private void OnClickedPlayerTwo()
	{
		auto& Member = Lobby.LobbyMembers[1];
		if (Member.Identity == nullptr)
			return;
		if (!Member.Identity.TakesInputFromKeyboard())
			return;
		ToggleReady(Online::KeyboardInputDevice);
	}

	UFUNCTION()
	private void OnPlayerTwoLeft(UMenuArrowButtonWidget Widget)
	{
		auto& Member = Lobby.LobbyMembers[1];
		if (Member.Identity == nullptr)
			return;
		if (!Member.Identity.TakesInputFromKeyboard())
			return;
		MoveSelection(Online::KeyboardInputDevice, bMoveLeft = true);
	}

	UFUNCTION()
	private void OnPlayerTwoRight(UMenuArrowButtonWidget Widget)
	{
		auto& Member = Lobby.LobbyMembers[1];
		if (Member.Identity == nullptr)
			return;
		if (!Member.Identity.TakesInputFromKeyboard())
			return;
		MoveSelection(Online::KeyboardInputDevice, bMoveLeft = false);
	}

	void MoveSelection(FInputDeviceId Controller, bool bMoveLeft)
	{
		if (Lobby.HasGameStarted())
			return;

		for (auto& Member : Lobby.LobbyMembers)
		{
			if (Member.Identity == nullptr)
				continue;
			if (Member.Identity.TakesInputFromController(Controller))
			{
				EHazePlayer NewSelection = EHazePlayer::MAX;

				if (bMoveLeft)
				{
					switch (Member.ChosenPlayer)
					{
						case EHazePlayer::Mio:
						case EHazePlayer::MAX:
							NewSelection = EHazePlayer::Mio;
						break;
						case EHazePlayer::Zoe:
							NewSelection = EHazePlayer::MAX;
						break;
					}
				}
				else
				{
					switch (Member.ChosenPlayer)
					{
						case EHazePlayer::Mio:
							NewSelection = EHazePlayer::MAX;
						break;
						case EHazePlayer::Zoe:
						case EHazePlayer::MAX:
							NewSelection = EHazePlayer::Zoe;
						break;
					}
				}

				if (NewSelection != Member.ChosenPlayer)
				{
					Lobby::Menu_LobbySetReady(Member.Identity, false);
					Lobby::Menu_LobbySelectPlayer(Member.Identity, NewSelection);
				}
			}
		}
	}

	void ToggleReady(FInputDeviceId Controller)
	{
		if (Lobby.HasGameStarted())
			return;

		UHazePlayerIdentity KeyIdentityInLobby = Lobby.GetIdentityForInput(Controller);

		// Toggle ready state
		if (KeyIdentityInLobby != nullptr && Lobby.GetPlayerChosen(KeyIdentityInLobby) != EHazePlayer::MAX)
		{
			bool bOtherPlayerReadyHere = false;
			for (auto& Member : Lobby.LobbyMembers)
			{
				if (Member.Identity == KeyIdentityInLobby)
					continue;
				if (Member.Identity == nullptr)
					continue;
				if (Member.ChosenPlayer != Lobby.GetPlayerChosen(KeyIdentityInLobby))
					continue;
				if (!Member.bReady)
					continue;
				bOtherPlayerReadyHere = true;
				break;
			}

			if (!bOtherPlayerReadyHere)
			{
				bool bWasReady = Lobby.IsPlayerReady(KeyIdentityInLobby);

				UMenuEffectEventHandler::Trigger_OnCharacterSelected(
					Menu::GetAudioActor(), FCharacterSelectedData(Lobby.GetPlayerChosen(KeyIdentityInLobby), !bWasReady, false));
				
				if (!bWasReady || !bWantToStart)
					Lobby::Menu_LobbySetReady(KeyIdentityInLobby, !bWasReady);
			}
			else 
			{
				UMenuEffectEventHandler::Trigger_OnCharacterSelected(
					Menu::GetAudioActor(), FCharacterSelectedData(Lobby.GetPlayerChosen(KeyIdentityInLobby),false, true));
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	UWidget OnCustomNavigation(FGeometry Geometry, FNavigationEvent Event, EUINavigationRule& OutRule)
	{
		if (Lobby == nullptr || Lobby.HasGameStarted())
			return nullptr;

		// We respond to navigation here,
		// so analog stick can be used as well as dpad or keyboard.
		// We don't use the simulated buttons for the left stick,
		// because those are not nicely deadzoned.
		if (Event.NavigationType == EUINavigation::Left)
			MoveSelection(Event.InputDeviceId, bMoveLeft = true);
		if (Event.NavigationType == EUINavigation::Right)
			MoveSelection(Event.InputDeviceId, bMoveLeft = false);

		return nullptr;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry Geom, FKeyEvent Event)
	{
		// If the console is up, don't eat the key input
		if (Console::IsConsoleActive() || Console::IsConsoleKey(Event.Key))
			return FEventReply::Unhandled();
		if (Event.Key == EKeys::Gamepad_Special_Right)
			return FEventReply::Unhandled();
		if (Event.Key == EKeys::Gamepad_Special_Left)
			return FEventReply::Unhandled();
		if (Event.Key == EKeys::Escape && bPlayingCutscene)
			return FEventReply::Unhandled();
		if (Lobby == nullptr || Lobby.HasGameStarted())
			return FEventReply::Unhandled();
		if (Event.IsRepeat())
			return FEventReply::Unhandled();
		if (!bIsActive)
			return FEventReply::Handled();

		UHazePlayerIdentity KeyIdentity = Online::GetLocalIdentityAssociatedWithInputDevice(Event.InputDeviceId);
		UHazePlayerIdentity KeyIdentityInLobby = Lobby.GetIdentityForInput(Event.InputDeviceId);

		// Don't eat navigation keys to they can be used for custom navigation later
		if (Event.Key == EKeys::Left || Event.Key == EKeys::Right || Event.Key == EKeys::Up || Event.Key == EKeys::Down
		 || Event.Key == EKeys::Gamepad_DPad_Left || Event.Key == EKeys::Gamepad_DPad_Right
		 || Event.Key == EKeys::Gamepad_DPad_Up || Event.Key == EKeys::Gamepad_DPad_Down)
		{
			return FEventReply::Unhandled();
		}

		if (Event.Key == EKeys::Virtual_Accept || Event.Key == EKeys::Enter)
		{
			ToggleReady(Event.InputDeviceId);
			return FEventReply::Handled();
		}

		if (Event.Key == EKeys::Escape || Event.Key == EKeys::Virtual_Back)
		{
			// Un-ready for local player
			if (KeyIdentityInLobby != nullptr
				&& Lobby.GetPlayerChosen(KeyIdentityInLobby) != EHazePlayer::MAX
				&& Lobby.IsPlayerReady(KeyIdentityInLobby)
				&& !bWantToStart
				&& !Lobby.HasGameStarted())
			{
				Lobby::Menu_LobbySetReady(KeyIdentityInLobby, false);

				UMenuEffectEventHandler::Trigger_OnCharacterSelected(
					Menu::GetAudioActor(), 
					FCharacterSelectedData(Lobby.GetPlayerChosen(KeyIdentityInLobby), false, false));
				
				return FEventReply::Handled();
			}

			if (Lobby.LobbyOwner.IsLocal())
			{
				// Return to chapter select for owner of menu
				if (Lobby.StartType == EHazeLobbyStartType::NewGame)
				{
					// If we've just watched the New Game cutscene, we prompt to confirm leaving the Character Select screen
					// So we don't accidentally go back to the lobby and then have to watch (or skip) the new game cutscene again
					FMessageDialog Dialog;
					Dialog.Message = NSLOCTEXT("Lobby", "ReturnToLobbyQuestion", "Return back to the game lobby?");
					Dialog.AddOption(NSLOCTEXT("Lobby", "ConfirmReturnToLobby", "Back to Lobby"), FOnMessageDialogOptionChosen(this, n"Confirm_ReturnToLobby"));
					Dialog.AddCancelOption(FOnMessageDialogOptionChosen());

					ShowPopupMessage(Dialog, this);
				}
				else if (Lobby.StartType == EHazeLobbyStartType::Continue)
				{
					Lobby::Menu_LobbySetState(EHazeLobbyState::ChooseStartType);
					MainMenu.GotoLobbyChooseStartType();
				}
				else
				{
					Lobby::Menu_LobbySetState(EHazeLobbyState::ChapterSelect);
					MainMenu.GotoChapterSelect();
				}
				return FEventReply::Handled();
			}
			else
			{
				// Disconnect from lobby for joining player
				LeaveLobby();
				return FEventReply::Handled();
			}
		}

		// Special handling for WASD
		if (Event.Key == KeyboardBoundMoveLeft)
		{
			MoveSelection(Event.InputDeviceId, bMoveLeft = true);
			return FEventReply::Handled();
		}

		if (Event.Key == KeyboardBoundMoveRight)
		{
			MoveSelection(Event.InputDeviceId, bMoveLeft = false);
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION()
	private void Confirm_ReturnToLobby()
	{
		Lobby::Menu_LobbySetState(EHazeLobbyState::ChooseStartType);
		MainMenu.GotoLobbyChooseStartType();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geom, float DeltaTime)
	{
		Super::Tick(Geom, DeltaTime);

		if (Lobby == nullptr)
			return;
		if (MainMenu == nullptr)
			return;

		if (bPlayingCutscene)
		{
			if (MainMenu.CameraUser.ActiveLevelSequenceActor == nullptr)
			{
				OnNewGameCutsceneFinished();
				bPlayingCutscene = false;
			}
		}

		// Move the camera forward / back when starting the game
		if (Lobby.StartType == EHazeLobbyStartType::NewGame && IsValid(MainMenu))
		{
			auto Camera = MainMenu.StateCameras[int(EMainMenuState::LobbyCharacterSelect)].Camera;
			if (IsValid(Camera))
			{
				if (bWantToStart)
					CameraForwardMotion.AccelerateTo(FVector(200, 0, 0), 4.0, DeltaTime);
				else
					CameraForwardMotion.AccelerateTo(FVector(0, 0, 0), 4.0, DeltaTime);
				Camera.Camera.RelativeLocation = CameraForwardMotion.Value;
			}
		}

		if (Lobby.IsOkayToStartGame() && AreAllPlayersReady() && !Lobby.HasGameStarted() && bIsActive)
		{
			if (!bWantToStart)
			{
				if (Lobby.StartType == EHazeLobbyStartType::NewGame)
					StartTimer = 1.8;
				else
					StartTimer = 1.1;

				bWantToStart = true;

				UMenuEffectEventHandler::Trigger_OnStartGameInitiated(Menu::GetAudioActor());
			}
			else
			{
				float PrevTimer = StartTimer;
				StartTimer -= DeltaTime;

				float FadeStartPoint = 0.6;
				if (Lobby.StartType == EHazeLobbyStartType::NewGame)
						FadeStartPoint = 1.5;

				if (StartTimer < FadeStartPoint)
				{
					if (PrevTimer >= FadeStartPoint)
					{
						if (MainMenu.CameraUser != nullptr)
						{
							if (Lobby.StartType == EHazeLobbyStartType::NewGame)
							{
								// When starting a new game, fade to white because the opening cutscene starts at white
								MainMenu.CameraUser.FadeManagerComponent.AddFadeToColor(
									MainMenu.CameraUser, FLinearColor::White, -1.0, 1.5, 0.0, EFadePriority::Gameplay
								);
							}
							else
							{
								// Continuing an existing game fades to black normally
								MainMenu.CameraUser.FadeOutView(0.5);
							}
						}

						//MainMenu.OnGameProbablyStartingSoon.Broadcast();
					}

					CurrentOpacity = Math::FInterpConstantTo(CurrentOpacity, 0.0, DeltaTime, 2.0);
					SetRenderOpacity(CurrentOpacity);
				}

				if (StartTimer <= 0.0 && Lobby.LobbyOwner.IsLocal())
				{
					if (CVar_TestNewGameTransition.GetBool())
					{
						bWantToStart = false;
						MainMenu.CameraUser.FadeInView(0);

						Lobby::Menu_LobbySetState(EHazeLobbyState::ChooseStartType);
						MainMenu.GotoLobbyChooseStartType();
					}
					else
					{
						// If we're ever completely ready, lobby owner will decide to start the game.
						// No turning back now!
						bWantToStart = false;
						Lobby::Menu_StartLobbyGame();
						MainMenu.CloseMainMenu();

						CurrentOpacity = 0.0;
						SetRenderOpacity(0.0);
					}
				}
			}
		}
		else if (Lobby.HasGameStarted())
		{
			SetRenderOpacity(0.0);
		}
		else if (bWantToStart)
		{
			bWantToStart = false;
			if (MainMenu.CameraUser != nullptr)
				MainMenu.CameraUser.FadeInView(0.5);
		}
		else if (CurrentOpacity < 1.0)
		{
			CurrentOpacity = Math::FInterpConstantTo(CurrentOpacity, 1.0, DeltaTime, 2.0);
			SetRenderOpacity(CurrentOpacity);
		}

		// If the secondary identity is disengaged, remove it from the lobby and return to chapter select
		for (auto& Member : Lobby.LobbyMembers)
		{
			if (Member.Identity != nullptr && Member.Identity != Online::PrimaryIdentity)
			{
				if (Member.Identity.Engagement != EHazeIdentityEngagement::Engaged)
				{
					Lobby::Menu_RemoveLocalPlayerFromLobby(Member.Identity);
					Lobby::Menu_LobbySetState(EHazeLobbyState::LobbyPlayers);
					MainMenu.GotoLobbyPlayers();
				}
			}
		}

		UpdateWidgetState();
	}

	void OnNewGameCutsceneFinished()
	{
		MainMenu.UpdateChapterSelectMeshVisibility();
	}

	void UpdateWidgetState()
	{
		PlayerOneInfo.Update(Lobby.LobbyMembers[0]);
		PollForAudio(PlayerOneInfo, Lobby.LobbyMembers[0]);

		PlayerTwoInfo.Update(Lobby.LobbyMembers[1]);
		PollForAudio(PlayerTwoInfo, Lobby.LobbyMembers[1]);
	}

	void PollForAudio(ULobbyCharacterSelectPlayer PlayerWidget, FHazeLobbyMember LobbyMember)
	{
		if (PlayerWidget.PrevAudioPlayer != LobbyMember.ChosenPlayer)
		{
			bool bMovedLeft = false;
			if (PlayerWidget.PrevAudioPlayer == EHazePlayer::Zoe && LobbyMember.ChosenPlayer == EHazePlayer::MAX)
				bMovedLeft = true;
			else if (PlayerWidget.PrevAudioPlayer == EHazePlayer::MAX && LobbyMember.ChosenPlayer == EHazePlayer::Mio)
				bMovedLeft = true;

			OnCharacterMoveSelection.Broadcast(LobbyMember.ChosenPlayer, bMovedLeft);
			PlayerWidget.PrevAudioPlayer = LobbyMember.ChosenPlayer;
		}

		// Ready sound is already handled for local players, handle it for the remote player here
		// We don't unify these because local players have a special parameter for invalid readies
		// (when both players are selecting the same side)
		if (PlayerWidget.bPrevAudioReady != LobbyMember.bReady
			&& !LobbyMember.Identity.IsLocal())
		{
			UMenuEffectEventHandler::Trigger_OnCharacterSelected(
				Menu::GetAudioActor(),
				FCharacterSelectedData(LobbyMember.ChosenPlayer,
				LobbyMember.bReady, false));
			PlayerWidget.bPrevAudioReady = LobbyMember.bReady;
		}
	}

	bool AreAllPlayersReady()
	{
		if (Lobby.LobbyMembers.Num() != 2)
			return false;

		for (auto& Member : Lobby.LobbyMembers)
		{
			if (!Member.bReady)
				return false;
		}

		return true;
	}
};

class ULobbyCharacterSelectPlayer : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UTextBlock PlayerNameText;
	UPROPERTY(BindWidget)
	UImage ControllerImage;

	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_PS_Neutral;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_PS_Mio;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_PS_Zoe;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_PS_Mio_Ready;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_PS_Zoe_Ready;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_XB_Neutral;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_XB_Mio;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_XB_Zoe;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_XB_Mio_Ready;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_XB_Zoe_Ready;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_Sage_Pro_Neutral;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_Sage_Pro_Mio;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_Sage_Pro_Zoe;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_Sage_Pro_Mio_Ready;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_Sage_Pro_Zoe_Ready;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_Sage_DualJoycon_Neutral;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_Sage_DualJoycon_Mio;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_Sage_DualJoycon_Zoe;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_Sage_DualJoycon_Mio_Ready;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_Sage_DualJoycon_Zoe_Ready;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_Sage_Handheld_Neutral;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_Sage_Handheld_Mio;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_Sage_Handheld_Zoe;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_Sage_Handheld_Mio_Ready;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_Sage_Handheld_Zoe_Ready;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_KB_Neutral;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_KB_Mio;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_KB_Zoe;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_KB_Mio_Ready;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_KB_Zoe_Ready;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_Remote_Neutral;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_Remote_Mio;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_Remote_Zoe;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_Remote_Mio_Ready;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_Remote_Zoe_Ready;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_Generic_Neutral;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_Generic_Mio;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_Generic_Zoe;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_Generic_Mio_Ready;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D ControllerIcon_Generic_Zoe_Ready;

	UPROPERTY(BindWidget)
	UBorder PanelBackground;

	UPROPERTY(EditDefaultsOnly)
	UTexture2D PanelTexture_Neutral;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D PanelTexture_Mio;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D PanelTexture_Zoe;
	
	UPROPERTY(BindWidget)
	UImage CheckmarkImage;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D CheckmarkTexture_Mio;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D CheckmarkTexture_Zoe;

	UPROPERTY(BindWidget)
	UImage HeaderLine;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D HeaderLineTexture_Neutral;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D HeaderLineTexture_Mio;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D HeaderLineTexture_Zoe;

	UPROPERTY(BindWidget)
	UWidget ReadyPromptContainer;
	UPROPERTY(BindWidget)
	UWidget ReadiedContainer;
	UPROPERTY(BindWidget)
	UInputButtonWidget ReadyPromptButton;

	UPROPERTY(BindWidget)
	UMenuArrowButtonWidget LeftArrowButton;
	UPROPERTY(BindWidget)
	UMenuArrowButtonWidget RightArrowButton;

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

	EHazePlayer PrevAudioPlayer = EHazePlayer::MAX;
	bool bPrevAudioReady = false;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
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

	void Update(FHazeLobbyMember Member)
	{
		if (Member.Identity != nullptr)
		{
			PlayerNameText.SetText(Member.Identity.PlayerName);

			ControllerImage.SetVisibility(ESlateVisibility::HitTestInvisible);

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

			if (Member.Identity.IsLocal())
			{
				if (Member.ChosenPlayer == EHazePlayer::Mio)
				{
					if (Member.bReady)
					{
						if (Game::PlatformName == "PS5" || Lobby::CVar_UsePlaystationLobbyIcons.GetBool())
						{
							ControllerImage.SetBrushFromTexture(ControllerIcon_Generic_Mio_Ready);
						}
						else switch (Member.Identity.GetControllerType())
						{
							case EHazePlayerControllerType::Keyboard:
								ControllerImage.SetBrushFromTexture(ControllerIcon_KB_Mio_Ready);
							break;
							case EHazePlayerControllerType::None:
							case EHazePlayerControllerType::Xbox:
								ControllerImage.SetBrushFromTexture(ControllerIcon_XB_Mio_Ready);
							break;
							case EHazePlayerControllerType::PS4:
							case EHazePlayerControllerType::PS5:
								ControllerImage.SetBrushFromTexture(ControllerIcon_PS_Mio_Ready);
							break;
							case EHazePlayerControllerType::Sage_Pro:
								ControllerImage.SetBrushFromTexture(ControllerIcon_Sage_Pro_Mio_Ready);
							break;
							case EHazePlayerControllerType::Sage_DualJoycon:
								ControllerImage.SetBrushFromTexture(ControllerIcon_Sage_DualJoycon_Mio_Ready);
							break;
							case EHazePlayerControllerType::Sage_Handheld:
								ControllerImage.SetBrushFromTexture(ControllerIcon_Sage_Handheld_Mio_Ready);
							break;
						}
					}
					else
					{
						if (Game::PlatformName == "PS5" || Lobby::CVar_UsePlaystationLobbyIcons.GetBool())
						{
							ControllerImage.SetBrushFromTexture(ControllerIcon_Generic_Mio);
						}
						else switch (Member.Identity.GetControllerType())
						{
							case EHazePlayerControllerType::Keyboard:
								ControllerImage.SetBrushFromTexture(ControllerIcon_KB_Mio);
							break;
							case EHazePlayerControllerType::None:
							case EHazePlayerControllerType::Xbox:
								ControllerImage.SetBrushFromTexture(ControllerIcon_XB_Mio);
							break;
							case EHazePlayerControllerType::PS4:
							case EHazePlayerControllerType::PS5:
								ControllerImage.SetBrushFromTexture(ControllerIcon_PS_Mio);
							break;
							case EHazePlayerControllerType::Sage_Pro:
								ControllerImage.SetBrushFromTexture(ControllerIcon_Sage_Pro_Mio);
							break;
							case EHazePlayerControllerType::Sage_DualJoycon:
								ControllerImage.SetBrushFromTexture(ControllerIcon_Sage_DualJoycon_Mio);
							break;
							case EHazePlayerControllerType::Sage_Handheld:
								ControllerImage.SetBrushFromTexture(ControllerIcon_Sage_Handheld_Mio);
							break;
						}
					}
				}
				else if (Member.ChosenPlayer == EHazePlayer::Zoe)
				{
					if (Member.bReady)
					{
						if (Game::PlatformName == "PS5" || Lobby::CVar_UsePlaystationLobbyIcons.GetBool())
						{
							ControllerImage.SetBrushFromTexture(ControllerIcon_Generic_Zoe_Ready);
						}
						else switch (Member.Identity.GetControllerType())
						{
							case EHazePlayerControllerType::Keyboard:
								ControllerImage.SetBrushFromTexture(ControllerIcon_KB_Zoe_Ready);
							break;
							case EHazePlayerControllerType::None:
							case EHazePlayerControllerType::Xbox:
								ControllerImage.SetBrushFromTexture(ControllerIcon_XB_Zoe_Ready);
							break;
							case EHazePlayerControllerType::PS4:
							case EHazePlayerControllerType::PS5:
								ControllerImage.SetBrushFromTexture(ControllerIcon_PS_Zoe_Ready);
							break;
							case EHazePlayerControllerType::Sage_Pro:
								ControllerImage.SetBrushFromTexture(ControllerIcon_Sage_Pro_Zoe_Ready);
							break;
							case EHazePlayerControllerType::Sage_DualJoycon:
								ControllerImage.SetBrushFromTexture(ControllerIcon_Sage_DualJoycon_Zoe_Ready);
							break;
							case EHazePlayerControllerType::Sage_Handheld:
								ControllerImage.SetBrushFromTexture(ControllerIcon_Sage_Handheld_Zoe_Ready);
							break;
						}
					}
					else
					{
						if (Game::PlatformName == "PS5" || Lobby::CVar_UsePlaystationLobbyIcons.GetBool())
						{
							ControllerImage.SetBrushFromTexture(ControllerIcon_Generic_Zoe);
						}
						else switch (Member.Identity.GetControllerType())
						{
							case EHazePlayerControllerType::Keyboard:
								ControllerImage.SetBrushFromTexture(ControllerIcon_KB_Zoe);
							break;
							case EHazePlayerControllerType::None:
							case EHazePlayerControllerType::Xbox:
								ControllerImage.SetBrushFromTexture(ControllerIcon_XB_Zoe);
							break;
							case EHazePlayerControllerType::PS4:
							case EHazePlayerControllerType::PS5:
								ControllerImage.SetBrushFromTexture(ControllerIcon_PS_Zoe);
							break;
							case EHazePlayerControllerType::Sage_Pro:
								ControllerImage.SetBrushFromTexture(ControllerIcon_Sage_Pro_Zoe);
							break;
							case EHazePlayerControllerType::Sage_DualJoycon:
								ControllerImage.SetBrushFromTexture(ControllerIcon_Sage_DualJoycon_Zoe);
							break;
							case EHazePlayerControllerType::Sage_Handheld:
								ControllerImage.SetBrushFromTexture(ControllerIcon_Sage_Handheld_Zoe);
							break;
						}
					}
				}
				else
				{
					if (Game::PlatformName == "PS5" || Lobby::CVar_UsePlaystationLobbyIcons.GetBool())
					{
						ControllerImage.SetBrushFromTexture(ControllerIcon_Generic_Neutral);
					}
					else switch (Member.Identity.GetControllerType())
					{
						case EHazePlayerControllerType::Keyboard:
							ControllerImage.SetBrushFromTexture(ControllerIcon_KB_Neutral);
						break;
						case EHazePlayerControllerType::None:
						case EHazePlayerControllerType::Xbox:
							ControllerImage.SetBrushFromTexture(ControllerIcon_XB_Neutral);
						break;
						case EHazePlayerControllerType::PS4:
						case EHazePlayerControllerType::PS5:
							ControllerImage.SetBrushFromTexture(ControllerIcon_PS_Neutral);
						break;
						case EHazePlayerControllerType::Sage_Pro:
							ControllerImage.SetBrushFromTexture(ControllerIcon_Sage_Pro_Neutral);
						break;
						case EHazePlayerControllerType::Sage_DualJoycon:
							ControllerImage.SetBrushFromTexture(ControllerIcon_Sage_DualJoycon_Neutral);
						break;
						case EHazePlayerControllerType::Sage_Handheld:
							ControllerImage.SetBrushFromTexture(ControllerIcon_Sage_Handheld_Neutral);
						break;
					}
				}

				switch (Member.Identity.GetControllerType())
				{
					case EHazePlayerControllerType::Keyboard:
						LeftArrowButton.bClickable = true;
						RightArrowButton.bClickable = true;
					break;
					case EHazePlayerControllerType::None:
					case EHazePlayerControllerType::Xbox:
						LeftArrowButton.bClickable = false;
						RightArrowButton.bClickable = false;
					break;
					case EHazePlayerControllerType::PS4:
						LeftArrowButton.bClickable = false;
						RightArrowButton.bClickable = false;
					break;
					case EHazePlayerControllerType::PS5:
						LeftArrowButton.bClickable = false;
						RightArrowButton.bClickable = false;
					break;
					case EHazePlayerControllerType::Sage_Pro:
					case EHazePlayerControllerType::Sage_DualJoycon:
					case EHazePlayerControllerType::Sage_Handheld:
						LeftArrowButton.bClickable = false;
						RightArrowButton.bClickable = false;
					break;
				}
			}
			else
			{
				if (Member.ChosenPlayer == EHazePlayer::Mio)
				{
					ControllerImage.SetBrushFromTexture(ControllerIcon_Remote_Mio);
				}
				else if (Member.ChosenPlayer == EHazePlayer::Zoe)
				{
					ControllerImage.SetBrushFromTexture(ControllerIcon_Remote_Zoe);
				}
				else
				{
					ControllerImage.SetBrushFromTexture(ControllerIcon_Remote_Neutral);
				}

				LeftArrowButton.bClickable = false;
				RightArrowButton.bClickable = false;
			}

			if (Member.Identity != nullptr && !Member.Identity.IsLocal())
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

			if (Member.ChosenPlayer == EHazePlayer::Mio)
			{
				PanelBackground.SetBrushFromTexture(PanelTexture_Mio);
				CheckmarkImage.SetBrushFromTexture(CheckmarkTexture_Mio);
				HeaderLine.SetBrushFromTexture(HeaderLineTexture_Mio);
				ReadyPromptButton.OverridePlayer = EHazeSelectPlayer::Mio;
			}
			else if (Member.ChosenPlayer == EHazePlayer::Zoe)
			{
				PanelBackground.SetBrushFromTexture(PanelTexture_Zoe);
				HeaderLine.SetBrushFromTexture(HeaderLineTexture_Zoe);
				CheckmarkImage.SetBrushFromTexture(CheckmarkTexture_Zoe);
				ReadyPromptButton.OverridePlayer = EHazeSelectPlayer::Zoe;
			}
			else
			{
				PanelBackground.SetBrushFromTexture(PanelTexture_Neutral);
				HeaderLine.SetBrushFromTexture(HeaderLineTexture_Neutral);
				ReadyPromptButton.OverridePlayer = EHazeSelectPlayer::Both;
			}

			switch (Member.ChosenPlayer)
			{
				case EHazePlayer::Mio:
					SetRenderTranslation(FVector2D(-400.0, 0.0));
				break;
				case EHazePlayer::Zoe:
					SetRenderTranslation(FVector2D(400.0, 0.0));
				break;
				case EHazePlayer::MAX:
					SetRenderTranslation(FVector2D(0.0, 0.0));
				break;
			}

			if (Member.Identity.IsLocal())
				ReadyPromptButton.OverrideControllerType = Member.Identity.ControllerType;
			else
				ReadyPromptButton.OverrideControllerType = Lobby::GetMostLikelyControllerType();

			if (ReadyPromptButton.OverrideControllerType == EHazePlayerControllerType::Keyboard)
			{
				ReadyPromptButton.OverrideKey = EKeys::Enter;
				ReadyPromptButton.OverrideSpecialButton = EHazeSpecialInputButton::None;
			}
			else
			{
				ReadyPromptButton.OverrideKey = FKey();
				ReadyPromptButton.OverrideSpecialButton = EHazeSpecialInputButton::Virtual_Accept;
			}

			if (Member.bReady)
			{
				ReadiedContainer.Visibility = ESlateVisibility::HitTestInvisible;
				ReadyPromptContainer.Visibility = ESlateVisibility::Hidden;
			}
			else if (Member.ChosenPlayer != EHazePlayer::MAX)
			{
				ReadiedContainer.Visibility = ESlateVisibility::Hidden;
				ReadyPromptContainer.Visibility = ESlateVisibility::HitTestInvisible;
			}
			else
			{
				ReadiedContainer.Visibility = ESlateVisibility::Hidden;
				ReadyPromptContainer.Visibility = ESlateVisibility::Hidden;
			}

			if (Member.ChosenPlayer != EHazePlayer::Mio && !Member.bReady)
				LeftArrowButton.Visibility = ESlateVisibility::Visible;
			else
				LeftArrowButton.Visibility = ESlateVisibility::Hidden;

			if (Member.ChosenPlayer != EHazePlayer::Zoe && !Member.bReady)
				RightArrowButton.Visibility = ESlateVisibility::Visible;
			else
				RightArrowButton.Visibility = ESlateVisibility::Hidden;
		}
	}
};

UCLASS(Abstract)
class ULobbyCharacterSelectTabletWidget : UHazeUserWidget
{
}

UCLASS(Abstract)
class ALobbyCharacterSelectTablet : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase CharacterMesh;
	
	UPROPERTY(DefaultComponent, Attach = CharacterMesh, AttachSocket = RightAttach)
	UStaticMeshComponent Tablet;

	UPROPERTY(EditAnywhere)
	UBlendSpace Blendspace;

	UPROPERTY(EditAnywhere)
	UAnimSequence Enter;

	UPROPERTY(DefaultComponent)
	UWidgetComponent WidgetComp;
	default WidgetComp.RelativeLocation = FVector(0, 0, 99999999);
	default WidgetComp.ManuallyRedraw = true;
	default WidgetComp.DrawSize = FVector2D(540, 960);
	default WidgetComp.TickWhenOffscreen = true;

	UPROPERTY(EditAnywhere)
	UBinkMediaPlayer MediaPlayer;
	UPROPERTY(EditAnywhere)
	EHazePlayer AssociatedPlayer;

	// Whether the character is currently being selected by any player
	UPROPERTY()
	bool bCharacterIsSelected = false;

	bool bBinkPlaying = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AMainMenu Menu = ActorList::GetSingle(AMainMenu);

		if (Tablet.IsHiddenInGame())
			CharacterMesh.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::OnlyTickMontagesWhenNotRendered;
		else
			CharacterMesh.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;

		if (Tablet.IsHiddenInGame() || !IsValid(Menu) || Menu.CameraUser.ActiveLevelSequenceActor != nullptr)
		{
			if (bBinkPlaying)
			{
				MediaPlayer.Stop();
				bBinkPlaying = false;
			}
			return;
		}

		WidgetComp.RequestRenderUpdate();
		if (!bBinkPlaying)
		{
			MediaPlayer.Play();
			bBinkPlaying = true;
		}

		auto Lobby = Lobby::GetLobby();
		bCharacterIsSelected = false;
		if (Lobby != nullptr)
		{
			for (auto Identity : Lobby.LobbyMembers)
			{
				if (Identity.ChosenPlayer == AssociatedPlayer)
					bCharacterIsSelected = true;
			}
		}

		// PrintToScreen(f"{AssociatedPlayer} = {bCharacterIsSelected}");

		auto WidgetRenderTarget = WidgetComp.GetRenderTarget();
		if (WidgetRenderTarget != nullptr)
		{
			auto DynamicMaterial = Tablet.CreateDynamicMaterialInstance(1);
			DynamicMaterial.SetTextureParameterValue(n"TexM1", WidgetRenderTarget);
			DynamicMaterial.SetTextureParameterValue(n"TexM4", WidgetRenderTarget);
		}
	}
}

const FConsoleCommand ConsoleLeaveLobby("Haze.SimulateLeaveLobby", n"ExecuteSimulateLeaveLobby");
void ExecuteSimulateLeaveLobby(TArray<FString> Args)
{
	Lobby::Menu_LeaveLobby();
}