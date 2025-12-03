class ULobbyChooseStartTypeWidget : ULobbyWidgetBase
{
	default bShowMenuBackground = true;
	
	UPROPERTY(BindWidget)
	ULobbyStartTypeButton NewGameButton;
	UPROPERTY(BindWidget)
	ULobbyStartTypeButton ContinueButton;
	UPROPERTY(BindWidget)
	ULobbyStartTypeButton ChapterSelectButton;

	UPROPERTY(BindWidget)
	UWidget UIRoot;

	UPROPERTY(BindWidget)
	UChapterImageWidget ContinueChapterImage;
	UPROPERTY(BindWidget)
	UChapterImageWidget NewGameChapterImage;
	UPROPERTY(BindWidget)
	UChapterImageWidget ChapterSelectImage;
	UPROPERTY(BindWidget)
	UWidget ContinueDemoWarning;

	UPROPERTY(BindWidget)
	UMenuPromptOrButton BackButton;
	UPROPERTY(BindWidget)
	UMenuPromptOrButton ProceedButton;

	UPROPERTY()
	UTexture2D NewGameTexture;
	UPROPERTY()
	UTexture2D ChapterSelectTexture;


	FKCodeHandler KCodeHandler;

	bool bHasContinue = false;

	UHazeChapterDatabase ChapterDatabase;

	FHazeProgressPointRef ContinueChapter;
	FHazeProgressPointRef ContinuePoint;
	EHazeLobbyStartType CurrentStartType = EHazeLobbyStartType::NewGame;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		BackButton.OnPressed.AddUFunction(this, n"OnBackPressed");
		ProceedButton.OnPressed.AddUFunction(this, n"OnProceedPressed");
	}

	void OnTransitionEnter(EMainMenuState PreviousState, bool bSnap) override
	{
		Super::OnTransitionEnter(PreviousState, bSnap);

		ChapterDatabase = UHazeChapterDatabase::GetChapterDatabase();

		if (Lobby == nullptr)
			return;

		if (Lobby.LobbyOwner.IsLocal())
		{
			bHasContinue = Save::GetContinueProgress(ContinueChapter, ContinuePoint);
			// bHasContinue = false;

			// Select continue in chapter select if available
			if (Lobby.StartType == EHazeLobbyStartType::Default)
			{
				if (bHasContinue && Save::IsContinueStartable(ContinueChapter, ContinuePoint))
				{
					FHazeChapter Chapter = ChapterDatabase.GetChapterByProgressPoint(ContinueChapter);
					FHazeChapterGroup Group = ChapterDatabase.GetChapterGroup(Chapter);

					Lobby::Menu_LobbySelectStart(EHazeLobbyStartType::Continue, ContinueChapter, ContinuePoint);
				}
				else
				{
					Lobby::Menu_LobbySelectStart(EHazeLobbyStartType::NewGame, ChapterDatabase.InitialChapter, ChapterDatabase.InitialChapter);
				}
			}

			if (!bHasContinue)
			{
				ContinueButton.Visibility = ESlateVisibility::Collapsed;
				ChapterSelectButton.Visibility = ESlateVisibility::Collapsed;
			}
			else
			{
				UpdateContinueChapter();
			}

			ContinueButton.OnClicked.AddUFunction(this, n"OnContinueClicked");
			ContinueButton.OnFocused.AddUFunction(this, n"OnContinueFocused");

			NewGameButton.OnClicked.AddUFunction(this, n"OnNewGameClicked");
			NewGameButton.OnFocused.AddUFunction(this, n"OnNewGameFocused");
			
			ChapterSelectButton.OnClicked.AddUFunction(this, n"OnChapterSelectClicked");
			ChapterSelectButton.OnFocused.AddUFunction(this, n"OnChapterSelectFocused");
		}
		else
		{
			NewGameButton.bClickable = false;
			ContinueButton.bClickable = false;
			ChapterSelectButton.bClickable = false;

			BackButton.Text = NSLOCTEXT("MainMenuLobby", "DisconnectLobby", "Disconnect");
			BackButton.UpdateWidgets();
		}

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

		// Show images for new game and chapter select
		NewGameChapterImage.SetChapterImage(NewGameTexture);
		ChapterSelectImage.SetChapterImage(ChapterSelectTexture);

		FocusWidgetForStartType();
		UpdateWidgetState();
	}

	void OnTransitionExit(EMainMenuState NextState, bool bSnap) override
	{
		Super::OnTransitionExit(NextState, bSnap);
	}

	void UpdateAvailableButtons()
	{
		bHasContinue = Save::GetContinueProgress(ContinueChapter, ContinuePoint);
		if (bHasContinue)
		{
			ContinueButton.Visibility = ESlateVisibility::Visible;
			ChapterSelectButton.Visibility = ESlateVisibility::Visible;
		}
		else
		{
			ContinueButton.Visibility = ESlateVisibility::Collapsed;
			ChapterSelectButton.Visibility = ESlateVisibility::Collapsed;
		}
		UpdateContinueChapter();
	}

	void UpdateContinueChapter()
	{
		FHazeChapter Chapter = ChapterDatabase.GetChapterByProgressPoint(ContinueChapter);
		FHazeChapterGroup Group = ChapterDatabase.GetChapterGroup(Chapter);

		// ContinueGroupText.SetText(Group.GroupName);
		// ContinueGroupText.Visibility = ESlateVisibility::HitTestInvisible;

		ContinueChapterImage.SetChapterImage(Chapter.Image);
	}

	UFUNCTION()
	private void OnContinueClicked(UMenuButtonWidget Button)
	{
		SetLobbyStartType(EHazeLobbyStartType::Continue);
		Lobby::Menu_LobbySetState(EHazeLobbyState::CharacterSelect);
	}

	UFUNCTION()
	private void OnContinueFocused(UMenuButtonWidget Button)
	{
		if (Lobby.StartType != EHazeLobbyStartType::Continue)
			SetLobbyStartType(EHazeLobbyStartType::Continue);
	}

	UFUNCTION()
	private void OnNewGameClicked(UMenuButtonWidget Button)
	{
		SetLobbyStartType(EHazeLobbyStartType::NewGame);
		Lobby::Menu_LobbySetState(EHazeLobbyState::CharacterSelect);
	}

	UFUNCTION()
	private void OnNewGameFocused(UMenuButtonWidget Button)
	{
		if (Lobby.StartType != EHazeLobbyStartType::NewGame)
			SetLobbyStartType(EHazeLobbyStartType::NewGame);
	}

	UFUNCTION()
	private void OnChapterSelectClicked(UMenuButtonWidget Button)
	{
		SetLobbyStartType(EHazeLobbyStartType::ChapterSelect);
		Lobby::Menu_LobbySetState(EHazeLobbyState::ChapterSelect);
	}

	UFUNCTION()
	private void OnChapterSelectFocused(UMenuButtonWidget Button)
	{
		if (Lobby.StartType != EHazeLobbyStartType::ChapterSelect)
			SetLobbyStartType(EHazeLobbyStartType::ChapterSelect);
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry MyGeometry, FFocusEvent InFocusEvent)
	{
		if (Lobby != nullptr)
		{
			switch (Lobby.StartType)
			{
				case EHazeLobbyStartType::NewGame:
					return FEventReply::Handled().SetUserFocus(NewGameButton, InFocusEvent.Cause);
				case EHazeLobbyStartType::Continue:
					return FEventReply::Handled().SetUserFocus(ContinueButton, InFocusEvent.Cause);
				case EHazeLobbyStartType::ChapterSelect:
					return FEventReply::Handled().SetUserFocus(ChapterSelectButton, InFocusEvent.Cause);
				default:
				break;
			}
		}
		return FEventReply::Handled().SetUserFocus(NewGameButton, InFocusEvent.Cause);
	}

	void FocusWidgetForStartType()
	{
		if (IsMessageDialogShown())
			return;

		switch (Lobby.StartType)
		{
			case EHazeLobbyStartType::Continue:
				if (!ContinueButton.bFocused)
					Widget::SetAllPlayerUIFocus(ContinueButton);
			break;
			case EHazeLobbyStartType::ChapterSelect:
				if (!ChapterSelectButton.bFocused)
					Widget::SetAllPlayerUIFocus(ChapterSelectButton);
			break;
			case EHazeLobbyStartType::NewGame:
			default:
				if (!NewGameButton.bFocused)
					Widget::SetAllPlayerUIFocus(NewGameButton);
			break;
		}
	}

	void UpdateWidgetState()
	{
		if (!Lobby.LobbyOwner.IsLocal())
		{
			// Focus the correct button that the host is picking
			FocusWidgetForStartType();

			// If we have Continue selected make sure the chapter for it is updated
			if (Lobby.StartType == EHazeLobbyStartType::Continue && !bHasContinue)
			{
				ContinueChapter = Lobby.StartChapter;
				ContinuePoint = Lobby.StartProgressPoint;
				bHasContinue = true;
				UpdateContinueChapter();
			}

			ProceedButton.bDisabled = true;
		}
		else
		{
			ProceedButton.bDisabled = false;
		}

		if (bHasContinue)
		{
			if (Save::IsContinueStartable(ContinueChapter, ContinuePoint))
			{
				ContinueButton.bClickable = true;
				ContinueButton.bIsFocusable = true;
				ContinueDemoWarning.Visibility = ESlateVisibility::Hidden;
			}
			else
			{
				ContinueButton.bClickable = false;
				ContinueButton.bIsFocusable = false;
				ContinueDemoWarning.Visibility = ESlateVisibility::HitTestInvisible;
			}
		}

		if (BackButton.GetControllerType() == EHazePlayerControllerType::Keyboard)
			ProceedButton.Visibility = ESlateVisibility::Collapsed;
		else
			ProceedButton.Visibility = ESlateVisibility::Visible;
	}

	UFUNCTION()
	void SetLobbyStartType(EHazeLobbyStartType StartType)
	{
		if (!Lobby.LobbyOwner.IsLocal())
			return;
		if (Lobby.LobbyState != EHazeLobbyState::ChooseStartType)
			return;

		switch (StartType)
		{
			case EHazeLobbyStartType::NewGame:
			{
				Lobby::Menu_LobbySelectStart(
					EHazeLobbyStartType::NewGame,
					ChapterDatabase.GetInitialChapter(),
					ChapterDatabase.GetInitialChapter());
			}
			break;
			case EHazeLobbyStartType::ChapterSelect:
			{
				if (HasContinueSave())
				{
					// Keep selected chapter if we already had one
					if (Lobby.StartType == EHazeLobbyStartType::ChapterSelect)
					{
						Lobby::Menu_LobbySelectStart(
							EHazeLobbyStartType::ChapterSelect,
							Lobby.StartChapter,
							Lobby.StartProgressPoint);
					}
					else
					{
						Lobby::Menu_LobbySelectStart(
							EHazeLobbyStartType::ChapterSelect,
							ChapterDatabase.GetInitialChapter(),
							ChapterDatabase.GetInitialChapter());
					}
				}
			}
			break;
			case EHazeLobbyStartType::Continue:
			{
				if (HasContinueSave())
				{
					Lobby::Menu_LobbySelectStart(
						EHazeLobbyStartType::Continue,
						ContinueChapter,
						ContinuePoint);
				}
			}
			break;
			default:
			break;
		}
	}

	void ReturnToLobbyPlayers()
	{
		Lobby::Menu_LobbySetState(EHazeLobbyState::LobbyPlayers);
		MainMenu.GotoLobbyPlayers();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnPreviewKeyDown(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (KCodeHandler.AddInput(this, InKeyEvent.Key))
			return FEventReply::Handled();
		return FEventReply::Unhandled();
	}

	UFUNCTION()
	private void OnBackPressed(UHazeUserWidget Widget)
	{
		if (Lobby.LobbyOwner.IsLocal())
			ReturnToLobbyPlayers();
		else
			LeaveLobby();
	}

	UFUNCTION()
	private void OnProceedPressed(UHazeUserWidget Widget)
	{
		if (Lobby.LobbyOwner.IsLocal())
		{
			if (ContinueButton.HasAnyUserFocus())
				OnContinueClicked(ContinueButton);
			else if (NewGameButton.HasAnyUserFocus())
				OnNewGameClicked(NewGameButton);
			else if (ChapterSelectButton.HasAnyUserFocus())
				OnChapterSelectClicked(ChapterSelectButton);
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
		if (KCodeHandler.AddInput(this, Event.Key))
			return FEventReply::Handled();
		if (Event.IsRepeat())
			return FEventReply::Unhandled();
		if (!bIsActive)
			return FEventReply::Handled();

		UHazePlayerIdentity KeyIdentity = Online::GetLocalIdentityAssociatedWithInputDevice(Event.InputDeviceId);
		UHazePlayerIdentity KeyIdentityInLobby = Lobby.GetIdentityForInput(Event.InputDeviceId);

		if (Event.Key == EKeys::Escape || Event.Key == EKeys::Virtual_Back)
		{
			if (Lobby.LobbyOwner.TakesInputFromController(Event.InputDeviceId))
			{
				ReturnToLobbyPlayers();
				return FEventReply::Handled();
			}
			else
			{
				LeaveLobby();
				return FEventReply::Handled();
			}
		}

		return Super::OnKeyDown(Geom, Event);
	}

	UFUNCTION(BlueprintPure)
	bool HasContinueSave()
	{
		return bHasContinue;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geom, float Timer)
	{
		Super::Tick(Geom, Timer);

		if (Lobby == nullptr)
			return;

		UpdateWidgetState();
	}
};

class ULobbyStartTypeButton : UMenuButtonWidget
{
	default bIsFocusable = true;
	default Visibility = ESlateVisibility::Visible;

	UPROPERTY(BindWidget)
	UMenuPanelContainer PanelBackground;
	UPROPERTY(BindWidget)
	UImage HeaderLine;
	UPROPERTY(BindWidget)
	UWidget ConstellationEffect;
	UPROPERTY(BindWidget)
	UWidget BackgroundGradient;

	float CurrentScale = 1.0;

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		float WantedScale = 1.0;

		if (bFocused || bPressed || Time::GetRealTimeSince(LastPressedTime) < 0.3)
		{
			HeaderLine.Visibility = ESlateVisibility::HitTestInvisible;
			BackgroundGradient.Visibility = ESlateVisibility::HitTestInvisible;
			ConstellationEffect.Visibility = ESlateVisibility::HitTestInvisible;

			if (bPressed || Time::GetRealTimeSince(LastPressedTime) < 0.3)
			{
				WantedScale = 1.03;
				CurrentScale = 1.03;
			}
			else
			{
				WantedScale = 1.1;
			}
		}
		else
		{
			HeaderLine.Visibility = ESlateVisibility::Hidden;
			BackgroundGradient.Visibility = ESlateVisibility::Hidden;
			ConstellationEffect.Visibility = ESlateVisibility::Hidden;
			WantedScale = 1.0;
		}

		CurrentScale = Math::FInterpConstantTo(CurrentScale, WantedScale, InDeltaTime, 2.0);
		SetRenderScale(FVector2D(CurrentScale, CurrentScale));
	}
};