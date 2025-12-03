
enum EPauseMenuState
{
	PauseMenu,
	OptionsMenu,
	ChapterSelect,
};

const FConsoleVariable CVar_EnableDevMenu("Haze.EnableDevMenu", 0);
const FConsoleVariable CVar_HidePauseMenu("Haze.HidePauseMenu", 0);
const FConsoleVariable CVar_EnableSkipToNextCheckpoint("Haze.EnableSkipToNextCheckpoint", 0);

class UPauseMenu : UHazeUserWidget
{
	default bIsFocusable = true;
	default bCustomNavigation = true;
	default Visibility = ESlateVisibility::Visible;

	EPauseMenuState CurrentState = EPauseMenuState::PauseMenu;
	UPauseMenuButton LastFocusedButton = nullptr;

	UPROPERTY(BindWidget)
	UCanvasPanel BackgroundContainer;

	UPROPERTY(BindWidget)
	UCanvasPanel PlayerMenuCanvas;
	UPROPERTY(BindWidget)
	UWidget GradientClippingBox;
	UPROPERTY(BindWidget)
	UImage GradientImage;
	UPROPERTY(BindWidget)
	UImage TopBarImage;
	UPROPERTY(BindWidget)
	UImage PlayerPanelImage;

	UPROPERTY(BindWidget)
	UImage Vignette_TopRight;
	UPROPERTY(BindWidget)
	UImage Vignette_BottomRight;
	
	UPROPERTY(BindWidget)
	UImage Vignette_TopLeft;
	UPROPERTY(BindWidget)
	UImage Vignette_BottomLeft;

	UPROPERTY(BindWidget)
	UCanvasPanel PauseMenuCanvas;
	UPROPERTY(BindWidget)
	UWidget BackgroundBlur;

	UPROPERTY(BindWidget)
	UWidget HidePauseMenuPrompt;
	UPROPERTY(BindWidget)
	UTextBlock HidePauseMenuText;

	UPROPERTY(BindWidget)
	UCanvasPanel OptionsMenuCanvas;
	UPROPERTY(BindWidget)
	UOptionsMenu OptionsMenu;

	UPROPERTY(BindWidget)
	UCanvasPanel ChapterSelectCanvas;
	UPROPERTY(BindWidget)
	UChapterSelectWidget ChapterSelect;
	UPROPERTY(BindWidget)
	UMenuPromptOrButton ChapterSelectBackButton;
	UPROPERTY(BindWidget)
	UMenuPromptOrButton ChapterSelectProceedButton;

	UPROPERTY(BindWidget)
	UPauseMenuButton ResumeButton;
	UPROPERTY(BindWidget)
	UPauseMenuButton OptionsButton;
	UPROPERTY(BindWidget)
	UPauseMenuButton MainMenuButton;
	UPROPERTY(BindWidget)
	UPauseMenuButton QuitButton;
	UPROPERTY(BindWidget)
	UPauseMenuButton RestartCheckpointButton;
	UPROPERTY(BindWidget)
	UPauseMenuButton SkipCheckpointButton;
	UPROPERTY(BindWidget)
	UPauseMenuButton RestartSideStoryButton;
	UPROPERTY(BindWidget)
	UPauseMenuButton ReplaySideStoryButton;
	UPROPERTY(BindWidget)
	UPauseMenuButton ExitSideContentButton;
	UPROPERTY(BindWidget)
	UPauseMenuButton ChapterSelectButton;
	UPROPERTY(BindWidget)
	UPauseMenuButton DevMenuButton;
	UPROPERTY(BindWidget)
	UPauseMenuButton DevInputButton;

	UPROPERTY(BindWidget)
	UWidget InformationBoxesContainer;

	UPROPERTY(BindWidget)
	UWidget RemotePlayerBox;
	UPROPERTY(BindWidget)
	UHazeTextWidget RemotePlayerName;
	UPROPERTY(BindWidget)
	UImage RemotePlatformIcon;

	UPROPERTY()
	UTexture2D EAIcon;
	UPROPERTY()
	UTexture2D PlaystationIcon;
	UPROPERTY()
	UTexture2D XboxIcon;
	UPROPERTY()
	UTexture2D SageIcon;

	UPROPERTY()
	UMaterialInterface RightPlayerGradient;
	UPROPERTY()
	UTexture2D RightPlayerTopBarTexture;

	UPROPERTY(Category="Sounds")
	FSoundDefReference SoundDefReference;

	bool bEscapeDown = false;
	bool bMenuHidden = false;

	bool bIsRightPlayer = true;

	FHazeAcceleratedFloat PanelPosition;

	TPerPlayer<FPauseMenuCameraData> CameraData;

	UFUNCTION()
	void ClosePauseMenu()
	{
		Game::HazeGameInstance.ClosePauseMenu();
	}

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		OptionsMenu.OnClosed.AddUFunction(this, n"OnOptionsMenuClosed");

		ResumeButton.OnClicked.AddUFunction(this, n"OnResumeClicked");
		OptionsButton.OnClicked.AddUFunction(this, n"OnOptionsClicked");
		MainMenuButton.OnClicked.AddUFunction(this, n"OnMainMenuClicked");
		QuitButton.OnClicked.AddUFunction(this, n"OnQuitClicked");
		RestartCheckpointButton.OnClicked.AddUFunction(this, n"OnRestartClicked");
		SkipCheckpointButton.OnClicked.AddUFunction(this, n"OnSkipClicked");
		ExitSideContentButton.OnClicked.AddUFunction(this, n"OnExitSideContentClicked");
		RestartSideStoryButton.OnClicked.AddUFunction(this, n"OnRestartSideContentClicked");
		ReplaySideStoryButton.OnClicked.AddUFunction(this, n"OnReplaySideContentClicked");
		ChapterSelectButton.OnClicked.AddUFunction(this, n"OnChapterSelectClicked");
		DevMenuButton.OnClicked.AddUFunction(this, n"OnDevMenuClicked");

		ChapterSelectBackButton.OnPressed.AddUFunction(this, n"OnChapterSelectBackPressed");
		ChapterSelectProceedButton.OnPressed.AddUFunction(this, n"OnChapterSelectProceedPressed");

		if (!ShouldShowDevOptions())
			DevMenuButton.Visibility = ESlateVisibility::Collapsed;

		if (Game::IsConsoleBuild())
		{
			MainMenuButton.bIsLastOption = true;
			MainMenuButton.UpdateLine();

			QuitButton.SetVisibility(ESlateVisibility::Collapsed);
		}
		else
		{
			MainMenuButton.bIsLastOption = false;
			MainMenuButton.UpdateLine();

			QuitButton.bIsLastOption = true;
			QuitButton.UpdateLine();
		}

		DevInputButton.OnClicked.AddUFunction(this, n"OnDevInputClicked");

		UpdateDevInput();

		PauseMenuCanvas.RenderOpacity = 0.0;
		ChapterSelectCanvas.RenderOpacity = 0.0;
		OptionsMenuCanvas.RenderOpacity = 0.0;
		BackgroundContainer.RenderOpacity = 0.0;
		InformationBoxesContainer.RenderOpacity = 0.0;

		PauseMenuCanvas.Visibility = ESlateVisibility::HitTestInvisible;
		OptionsMenuCanvas.Visibility = ESlateVisibility::HitTestInvisible;
		ChapterSelectCanvas.Visibility = ESlateVisibility::HitTestInvisible;

		bIsRightPlayer = Game::HazeGameInstance != nullptr && Game::HazeGameInstance.GetPausingPlayer() == EHazeSelectPlayer::Zoe;

		auto PlayerMenuSlot = Cast<UCanvasPanelSlot>(PlayerMenuCanvas.Slot);
		if (bIsRightPlayer)
		{
			PlayerMenuSlot.SetAnchors(FAnchors(1.0, 0.0, 1.0, 1.0));

			FMargin Offsets = PlayerMenuSlot.GetOffsets();
			Offsets.Left = 0.0;
			PlayerMenuSlot.SetOffsets(Offsets);
			PanelPosition.SnapTo(0.0);

			auto PauseMenuSlot = Cast<UCanvasPanelSlot>(PauseMenuCanvas.Slot);
			PauseMenuSlot.SetOffsets(FMargin(0, 0, 360, 0));

			PlayerPanelImage.SetRenderScale(FVector2D(-1.0, 1.0));

			auto PanelImageSlot = Cast<UCanvasPanelSlot>(PlayerPanelImage.Slot);
			PanelImageSlot.SetOffsets(FMargin(-21, -10, 990, -10));

			GradientImage.SetBrushFromMaterial(RightPlayerGradient);
			TopBarImage.SetBrushFromTexture(RightPlayerTopBarTexture);

			Vignette_TopRight.Visibility = ESlateVisibility::Collapsed;
			Vignette_BottomRight.Visibility = ESlateVisibility::Collapsed;

			auto OptionsMenuSlot = Cast<UCanvasPanelSlot>(OptionsMenuCanvas.Slot);
			OptionsMenuSlot.SetOffsets(FMargin(0));

			auto InformationSlot = Cast<UCanvasPanelSlot>(InformationBoxesContainer.Slot);
			InformationSlot.SetAnchors(FAnchors(0, 0, 0, 0));
			InformationSlot.SetAlignment(FVector2D(0, 0));
			InformationSlot.SetOffsets(FMargin(30, 30, 0, 0));
		}
		else
		{
			PlayerMenuSlot.SetAnchors(FAnchors(0.0, 0.0, 0.0, 1.0));

			FMargin Offsets = PlayerMenuSlot.GetOffsets();
			Offsets.Left = -960.0;
			PlayerMenuSlot.SetOffsets(Offsets);
			PanelPosition.SnapTo(-960.0);

			auto PanelImageSlot = Cast<UCanvasPanelSlot>(PlayerPanelImage.Slot);
			PanelImageSlot.SetOffsets(FMargin(-9, -10, 990, -10));

			Vignette_TopLeft.Visibility = ESlateVisibility::Collapsed;
			Vignette_BottomLeft.Visibility = ESlateVisibility::Collapsed;
		}
	}

	UFUNCTION()
	private void OnChapterSelectProceedPressed(UHazeUserWidget Widget = nullptr)
	{
		if (!Progress::Menu_CanChapterSelect())
			return;
		auto SelectedItem = ChapterSelect.GetSelectedItem();
		if (!Save::IsContinueStartable(SelectedItem.ChapterRef, SelectedItem.ProgressPointRef))
			return;
		if (!SelectedItem.bChapterUnlocked)
			return;
		if (SelectedItem.bIsSideContent && !SelectedItem.bIsSideContentUnlocked)
			return;

		if (Widget == nullptr)
		{
			UMenuEffectEventHandler::Trigger_OnDefaultClick(
				Menu::GetAudioActor(), FMenuActionData(ChapterSelectProceedButton, false)
			);
		}

		FMessageDialog Dialog;
		Dialog.Message = NSLOCTEXT("PauseMenu", "PromptChapterSelect", "Play from the start of another chapter?\nAny progress in the current chapter will be lost.");
		Dialog.AddOption(
			NSLOCTEXT("PauseMenu", "PlayChapter", "Play Chapter"),
			FOnMessageDialogOptionChosen(this, n"OnConfirmChapterSelect"),
		);
		Dialog.AddCancelOption();

		ShowPopupMessage(Dialog, this);
	}

	UFUNCTION()
	private void OnConfirmChapterSelect()
	{
		if (!Progress::Menu_CanChapterSelect())
			return;
		auto SelectedItem = ChapterSelect.GetSelectedItem();
		if (!Save::IsContinueStartable(SelectedItem.ChapterRef, SelectedItem.ProgressPointRef))
			return;
		if (!SelectedItem.bChapterUnlocked)
			return;
		if (SelectedItem.bIsSideContent && !SelectedItem.bIsSideContentUnlocked)
			return;

		ClosePauseMenu();
		Game::GetSingleton(UGlobalMenuSingleton).NetResetTimers();
		Progress::Menu_ChapterSelect(SelectedItem.ProgressPointRef);
	}

	UFUNCTION()
	private void OnChapterSelectBackPressed(UHazeUserWidget Widget = nullptr)
	{
		SwitchToState(EPauseMenuState::PauseMenu);
	}

	UFUNCTION()
	private void OnDevInputClicked(UMenuButtonWidget Button)
	{
		int Enabled = Console::GetConsoleVariableInt("Haze.EnableDevInput");
		if (Enabled == 0)
			Console::SetConsoleVariableInt("Haze.EnableDevInput", 1);
		else
			Console::SetConsoleVariableInt("Haze.EnableDevInput", 0);
		UpdateDevInput();
		UpdateDevHiddenState();
	}

	void UpdateDevInput()
	{
		int Enabled = Console::GetConsoleVariableInt("Haze.EnableDevInput");
		if (ShouldShowDevOptions()
#if !RELEASE
			&& (Enabled == 0 || Debug::IsUXTestBuild())
#endif
		)
		{
			if (Enabled == 0)
				DevInputButton.ButtonText.SetText(FText::FromString("(DEV) Enable Dev Shortcuts"));
			else
				DevInputButton.ButtonText.SetText(FText::FromString("(DEV) Disable Dev Shortcuts"));

			DevInputButton.Visibility = ESlateVisibility::Visible;
		}
		else
		{
			DevInputButton.Visibility = ESlateVisibility::Collapsed;
		}

		if (IsDevInputEnabled())
		{
			HidePauseMenuPrompt.Visibility = ESlateVisibility::HitTestInvisible;
		}
		else
		{
			HidePauseMenuPrompt.Visibility = ESlateVisibility::Collapsed;
		}
	}

	void UpdateDevHiddenState()
	{
		if (IsPauseMenuHidden())
		{
			if (!bMenuHidden)
			{
				BackgroundBlur.Visibility = ESlateVisibility::Hidden;
				PauseMenuCanvas.Visibility = ESlateVisibility::Hidden;
				PlayerMenuCanvas.Visibility = ESlateVisibility::Hidden;
				BackgroundContainer.Visibility = ESlateVisibility::Hidden;
				InformationBoxesContainer.Visibility = ESlateVisibility::Hidden;
				HidePauseMenuText.SetText(FText::FromString("Show Pause Menu"));
				bMenuHidden = true;

				// Set keybind capture so both controllers allow input through,
				// which is used for the debug camera
				Game::HazeGameInstance.bIsCapturingKeybind = true;
			}
		}
		else
		{
			if (bMenuHidden)
			{
				BackgroundBlur.Visibility = ESlateVisibility::SelfHitTestInvisible;
				BackgroundContainer.Visibility = ESlateVisibility::SelfHitTestInvisible;
				InformationBoxesContainer.Visibility = ESlateVisibility::SelfHitTestInvisible;
				PlayerMenuCanvas.Visibility = ESlateVisibility::SelfHitTestInvisible;
				PauseMenuCanvas.Visibility = ESlateVisibility::SelfHitTestInvisible;
				HidePauseMenuText.SetText(FText::FromString("Hide Pause Menu"));
				bMenuHidden = false;

				Game::HazeGameInstance.bIsCapturingKeybind = false;
				RemovePauseMenuCameras();
			}
		}
	}

	bool IsPauseMenuHidden()
	{
		return CVar_HidePauseMenu.GetInt() != 0;
	}

	void ToggleHidePauseMenu()
	{
		if (CVar_HidePauseMenu.GetInt() == 0)
			CVar_HidePauseMenu.SetInt(1);
		else
			CVar_HidePauseMenu.SetInt(0);

		UpdateDevHiddenState();
	}

	UFUNCTION()
	private void OnResumeClicked(UMenuButtonWidget Button)
	{
		ClosePauseMenu();
	}

	UFUNCTION()
	private void OnOptionsClicked(UMenuButtonWidget Button)
	{
		SwitchToState(EPauseMenuState::OptionsMenu);
	}

	UFUNCTION()
	private void OnChapterSelectClicked(UMenuButtonWidget Button)
	{
		SwitchToState(EPauseMenuState::ChapterSelect);
	}

	FText AppendLastSaveTimeToMessage(FText Message)
	{
		float TimeSinceSave = Save::GetTimeSinceLastSave();
		if (TimeSinceSave < 0.0)
			return Message;

		if (TimeSinceSave <= 60.0)
		{
			return FText::Format(
				NSLOCTEXT("PauseMenu", "AppendSavedLastMinute", "{0}\n\nLast saved less than one minute ago."),
				Message
			);
		}
		else
		{
			return FText::Format(
				NSLOCTEXT("PauseMenu", "AppendSavedLastTime", "{0}\n\nLast saved {1} minutes ago."),
				Message, Math::CeilToInt(TimeSinceSave / 60.0)
			);
		}
	}

	UFUNCTION()
	private void OnMainMenuClicked(UMenuButtonWidget Button)
	{
		FMessageDialog Dialog;
		Dialog.Message = NSLOCTEXT("PauseMenu", "PromptReturnToMainMenu", "Return to the main menu?\nAny progress since the last save will be lost.");
		Dialog.Message = AppendLastSaveTimeToMessage(Dialog.Message);
		Dialog.AddOption(
			NSLOCTEXT("PauseMenu", "AcceptReturn", "Return to Main Menu"),
			FOnMessageDialogOptionChosen(this, n"OnConfirmReturnToMainMenu"),
		);
		Dialog.AddCancelOption();

		ShowPopupMessage(Dialog, this);
	}

	UFUNCTION()
	private void OnConfirmReturnToMainMenu()
	{
		Progress::ReturnToMainMenu();
		ClosePauseMenu();
	}

	UFUNCTION()
	private void OnQuitClicked(UMenuButtonWidget Button)
	{
		FMessageDialog Dialog;
		Dialog.Message = NSLOCTEXT("PauseMenu", "PromptQuitGame", "Quit the game?\nAny progress since the last save will be lost.");
		Dialog.Message = AppendLastSaveTimeToMessage(Dialog.Message);
		Dialog.AddOption(
			NSLOCTEXT("PauseMenu", "AcceptQuit", "Quit Game"),
			FOnMessageDialogOptionChosen(this, n"OnConfirmQuit"),
		);
		Dialog.AddCancelOption();

		ShowPopupMessage(Dialog, this);
	}

	UFUNCTION()
	private void OnConfirmQuit()
	{
		Game::QuitGame();
	}

	bool CanChapterSelect()
	{
		return Progress::Menu_CanChapterSelect();
	}

	bool CanRestartCheckpoint()
	{
		return Progress::Menu_CanCheckpointRestart();
	}

	UFUNCTION()
	private void OnRestartClicked(UMenuButtonWidget Button)
	{
		FMessageDialog Dialog;
		Dialog.Message = NSLOCTEXT("PauseMenu", "PromptRestartCheckpoint", "Restart from latest checkpoint?\nAny progress since the last saved checkpoint will be lost.");
		Dialog.Message = AppendLastSaveTimeToMessage(Dialog.Message);
		Dialog.AddOption(
			NSLOCTEXT("PauseMenu", "AcceptRestartCheckpoint", "Restart from Checkpoint"),
			FOnMessageDialogOptionChosen(this, n"OnConfirmRestart"),
		);
		Dialog.AddCancelOption();

		ShowPopupMessage(Dialog, this);
	}

	UFUNCTION()
	private void OnConfirmRestart()
	{
		ClosePauseMenu();
		Progress::Menu_CheckpointRestart();
	}

	bool CanSkipCheckpoint()
	{
		if (!CVar_EnableSkipToNextCheckpoint.GetBool())
			return false;

		// Don't allow skipping while in a cutscene. The cutscene should handle its own skipping.
		for (AHazePlayerCharacter SkipPlayer : Game::Players)
		{
			if (SkipPlayer.bIsControlledByCutscene || SkipPlayer.IsCapabilityTagBlocked(CapabilityTags::BlockedByCutscene))
				return false;
		}
		
		return Progress::Menu_CanSkipCurrentSection();
	}

	UFUNCTION()
	private void OnSkipClicked(UMenuButtonWidget Button)
	{
		FMessageDialog Dialog;
		Dialog.Message = NSLOCTEXT("PauseMenu", "PromptSkipCheckpoint", "Skip to the next checkpoint in the game?\nRemaining cutscenes, puzzles, and gameplay in the current section will be missed.");
		Dialog.AddOption(
			NSLOCTEXT("PauseMenu", "AcceptSkipCheckpoint", "Skip to Next Checkpoint"),
			FOnMessageDialogOptionChosen(this, n"OnConfirmSkip"),
		);
		Dialog.AddCancelOption();

		ShowPopupMessage(Dialog, this);
	}

	UFUNCTION()
	private void OnConfirmSkip()
	{
		ClosePauseMenu();
		Progress::Menu_SkipCurrentSection();
	}

	bool CanExitSideContent()
	{
		return Progress::Menu_CanExitSideContent();
	}

	UFUNCTION()
	private void OnExitSideContentClicked(UMenuButtonWidget Button)
	{
		FMessageDialog Dialog;
		Dialog.Message = NSLOCTEXT("PauseMenu", "PromptExitSideContent", "Exit the current side story?");
		Dialog.AddOption(
			NSLOCTEXT("PauseMenu", "AcceptExitSideContent", "Exit Side Story"),
			FOnMessageDialogOptionChosen(this, n"OnConfirmExitSideContent"),
		);
		Dialog.AddCancelOption();

		ShowPopupMessage(Dialog, this);
	}

	UFUNCTION()
	private void OnConfirmExitSideContent()
	{
		ClosePauseMenu();
		Progress::Menu_ExitSideContent();
	}

	bool CanRestartSideContent()
	{
		return Progress::Menu_CanRestartSideContent();
	}

	UFUNCTION()
	private void OnRestartSideContentClicked(UMenuButtonWidget Button)
	{
		FMessageDialog Dialog;
		Dialog.Message = NSLOCTEXT("PauseMenu", "PromptRestartSideContent", "Restart the current side story?");
		Dialog.AddOption(
			NSLOCTEXT("PauseMenu", "AcceptRestartSideContent", "Restart Side Story"),
			FOnMessageDialogOptionChosen(this, n"OnConfirmRestartSideContent"),
		);
		Dialog.AddCancelOption();

		ShowPopupMessage(Dialog, this);
	}

	UFUNCTION()
	private void OnConfirmRestartSideContent()
	{
		ClosePauseMenu();
		Progress::Menu_RestartSideContent();
	}

	bool CanReplaySideContent()
	{
		return Progress::Menu_CanReplaySideContent();
	}

	UFUNCTION()
	private void OnReplaySideContentClicked(UMenuButtonWidget Button)
	{
		FMessageDialog Dialog;
		Dialog.Message = NSLOCTEXT("PauseMenu", "PromptReplaySideContent", "Replay the most recent side story?\nAll progress since exiting the side story will be lost.");
		Dialog.AddOption(
			NSLOCTEXT("PauseMenu", "AcceptReplaySideContent", "Replay Side Story"),
			FOnMessageDialogOptionChosen(this, n"OnConfirmReplaySideContent"),
		);
		Dialog.AddCancelOption();

		ShowPopupMessage(Dialog, this);
	}

	UFUNCTION()
	private void OnConfirmReplaySideContent()
	{
		ClosePauseMenu();
		Progress::Menu_ReplaySideContent();
	}

	UFUNCTION()
	private void OnDevMenuClicked(UMenuButtonWidget Button)
	{
		ClosePauseMenu();
		DevMenu::OpenDevMenuOverlay();
	}

	UFUNCTION(BlueprintPure)
	bool IsDevInputEnabled() const
	{
		if (!ShouldShowDevOptions())
			return false;
		int Enabled = Console::GetConsoleVariableInt("Haze.EnableDevInput");
		return (Enabled != 0);
	}

	UFUNCTION(BlueprintPure)
	bool ShouldShowDevOptions() const
	{
#if TEST
		return true;
#else
		if (Game::HazeGameInstance != nullptr)
		{
			if (Game::HazeGameInstance.IsTrialUpsellNeeded())
				return false;
		}
		return (CVar_EnableDevMenu.GetInt() != 0);
#endif
	}

	UFUNCTION()
	private void OnOptionsMenuClosed()
	{
		SwitchToState(EPauseMenuState::PauseMenu);
	}

	UFUNCTION(BlueprintOverride)
	void OnAdded()
	{
		Menu::AttachSoundDef(SoundDefReference, this);

		SwitchToState(EPauseMenuState::PauseMenu);
		Widget::SetAllPlayerUIFocus(this);
		Widget::SetUseMouseCursor(this, true);
		SetWidgetZOrderInLayer(800);
		UpdateDevInput();
		UpdateDevHiddenState();
	}

	UFUNCTION(BlueprintOverride)
	void RemoveFromScreen()
	{

		if (LastFocusedButton != nullptr && LastFocusedButton.bFocused)
			LastFocusedButton.LastPressedTime = Time::RealTimeSeconds;

		SetVisibility(ESlateVisibility::HitTestInvisible);
		Widget::SetUseMouseCursor(this, false);
		Widget::ClearAllPlayerUIFocus();
		RemovePauseMenuCameras();
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Menu::RemoveSoundDef(SoundDefReference, this);
	}

	UFUNCTION()
	void SwitchToState(EPauseMenuState NewState)
	{
		CurrentState = NewState;
		PauseMenuCanvas.Visibility = (NewState == EPauseMenuState::PauseMenu)
				? ESlateVisibility::SelfHitTestInvisible : ESlateVisibility::HitTestInvisible;
		OptionsMenuCanvas.Visibility = (NewState == EPauseMenuState::OptionsMenu)
				? ESlateVisibility::SelfHitTestInvisible : ESlateVisibility::HitTestInvisible;
		ChapterSelectCanvas.Visibility = (NewState == EPauseMenuState::ChapterSelect)
				? ESlateVisibility::SelfHitTestInvisible : ESlateVisibility::HitTestInvisible;

		UMenuEffectEventHandler::Trigger_OnPauseMenuStateChanged(
			Menu::GetAudioActor(), FPauseMenuStateChangeData(this, CurrentState)
		);

		if (NewState == EPauseMenuState::ChapterSelect)
		{
			ChapterSelect.Refresh();

			FHazeProgressPointRef ContinueChapter;
			FHazeProgressPointRef ContinueProgressPoint;
			if (Save::GetContinueProgress(ContinueChapter, ContinueProgressPoint))
				ChapterSelect.SetSelectedItem(ContinueChapter, ContinueProgressPoint);

			Widget::SetAllPlayerUIFocus(ChapterSelect);
		}
		else if (NewState == EPauseMenuState::PauseMenu)
		{
			// Focus the first button when we get focus
			if (LastFocusedButton != nullptr && LastFocusedButton.IsVisible())
				Widget::SetAllPlayerUIFocus(LastFocusedButton);
			else
				Widget::SetAllPlayerUIFocus(GetFirstButton());
		}
		else if (NewState == EPauseMenuState::OptionsMenu)
		{
			OptionsMenu.NarrateFullMenu();
			Widget::SetAllPlayerUIFocus(this);
		}
		else
		{
			devError(f"Bad PauseMenuState {NewState}");
			Widget::SetAllPlayerUIFocus(this);
		}
	}

	UFUNCTION(BlueprintPure)
	bool ShouldShowRemotePlayer()
	{
		auto Lobby = Lobby::GetLobby();
		if (Lobby == nullptr)
			return false;
		return Lobby.Network != EHazeLobbyNetwork::Local;
	}

	UFUNCTION(BlueprintPure)
	FText GetRemotePlayerName()
	{
		auto Lobby = Lobby::GetLobby();
		if (Lobby == nullptr)
			return FText();
		if (Lobby.Network == EHazeLobbyNetwork::Local)
			return FText();

		FText RemoteName = Online::GetRemotePlayerName();
		if (!RemoteName.IsEmpty())
			return RemoteName;

		for (auto& Member : Lobby.LobbyMembers)
		{
			if (Member.Identity == nullptr)
				continue;
			if (Member.Identity.IsLocal())
				continue;
			return Member.Identity.PlayerName;
		}
		return FText();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		// Ensure the UI focus is always on us
		if (Widget::IsAnyUserFocusGameViewportOrNone() && bIsAdded)
			Widget::SetAllPlayerUIFocusBeneathParent(this);

		if (ShouldShowRemotePlayer())
		{
			RemotePlayerBox.Visibility = ESlateVisibility::Visible;

			if (Game::IsConsoleBuild())
			{
				if (Online::IsRemotePlayerNameEAID())
				{
					RemotePlatformIcon.Visibility = ESlateVisibility::Visible;
					RemotePlatformIcon.SetBrushFromTexture(EAIcon);
				}
				else
				{
					RemotePlatformIcon.Visibility = ESlateVisibility::Visible;
					if (Game::PlatformName == "PS5")
						RemotePlatformIcon.SetBrushFromTexture(PlaystationIcon);
					else if (Game::PlatformName == "XSX")
						RemotePlatformIcon.SetBrushFromTexture(XboxIcon);
					else if (Game::PlatformName == "Sage")
						RemotePlatformIcon.SetBrushFromTexture(SageIcon);
					else
						RemotePlatformIcon.SetBrushFromTexture(EAIcon);
				}
			}
			else
			{
				if (Online::OnlinePlatformName == "Steam" && Online::IsRemotePlayerNameEAID())
				{
					RemotePlatformIcon.Visibility = ESlateVisibility::Visible;
					RemotePlatformIcon.SetBrushFromTexture(EAIcon);
				}
				else
				{
					RemotePlatformIcon.Visibility = ESlateVisibility::Collapsed;
				}
			}

			RemotePlayerName.SetText(GetRemotePlayerName());
		}
		else
		{
			RemotePlayerBox.Visibility = ESlateVisibility::Hidden;
		}

		if (CanRestartCheckpoint())
		{
			RestartCheckpointButton.Visibility = ESlateVisibility::Visible;
		}
		else
		{
			bool bWasFocused = RestartCheckpointButton.bFocused;
			RestartCheckpointButton.Visibility = ESlateVisibility::Collapsed;
			if (bWasFocused)
				Widget::SetAllPlayerUIFocus(this);
		}

		if (CanSkipCheckpoint())
		{
			SkipCheckpointButton.Visibility = ESlateVisibility::Visible;
		}
		else
		{
			bool bWasFocused = SkipCheckpointButton.bFocused;
			SkipCheckpointButton.Visibility = ESlateVisibility::Collapsed;
			if (bWasFocused)
				Widget::SetAllPlayerUIFocus(this);
		}

		if (CanExitSideContent())
		{
			ExitSideContentButton.Visibility = ESlateVisibility::Visible;
		}
		else
		{
			bool bWasFocused = ExitSideContentButton.bFocused;
			ExitSideContentButton.Visibility = ESlateVisibility::Collapsed;
			if (bWasFocused)
				Widget::SetAllPlayerUIFocus(this);
		}

		if (CanRestartSideContent())
		{
			RestartSideStoryButton.Visibility = ESlateVisibility::Visible;
		}
		else
		{
			bool bWasFocused = RestartSideStoryButton.bFocused;
			RestartSideStoryButton.Visibility = ESlateVisibility::Collapsed;
			if (bWasFocused)
				Widget::SetAllPlayerUIFocus(this);
		}

		if (CanReplaySideContent())
		{
			ReplaySideStoryButton.Visibility = ESlateVisibility::Visible;
		}
		else
		{
			bool bWasFocused = ReplaySideStoryButton.bFocused;
			ReplaySideStoryButton.Visibility = ESlateVisibility::Collapsed;
			if (bWasFocused)
				Widget::SetAllPlayerUIFocus(this);
		}

		if (CanChapterSelect())
		{
			ChapterSelectButton.Visibility = ESlateVisibility::Visible;
		}
		else
		{
			bool bWasFocused = ChapterSelectButton.bFocused;
			ChapterSelectButton.Visibility = ESlateVisibility::Collapsed;
			if (bWasFocused)
				Widget::SetAllPlayerUIFocus(this);

			if (CurrentState == EPauseMenuState::ChapterSelect)
				SwitchToState(EPauseMenuState::PauseMenu);
		}

		UpdatePauseMenuCamera(EHazePlayer::Mio, InDeltaTime);
		UpdatePauseMenuCamera(EHazePlayer::Zoe, InDeltaTime);

		UpdatePlayerMenu(InDeltaTime);
	}

	float MenuOpacity = 0.0;
	void UpdatePlayerMenu(float DeltaTime)
	{
		bool bFullyExpanded = false;
		bool bFullyRetracted = false;
		if (bIsRightPlayer)
		{
			auto PlayerMenuSlot = Cast<UCanvasPanelSlot>(PlayerMenuCanvas.Slot);
			FMargin Offsets = PlayerMenuSlot.GetOffsets();
			if (!bIsAdded)
				PanelPosition.AccelerateToWithStop(40.0, 0.4, DeltaTime, 50.0);
			else if (CurrentState == EPauseMenuState::PauseMenu)
				PanelPosition.AccelerateToWithStop(-600.0, 0.4, DeltaTime, 50.0);
			else
				PanelPosition.AccelerateToWithStop(-960.0, 0.4, DeltaTime, 50.0);
			Offsets.Left = PanelPosition.Value;
			PlayerMenuSlot.SetOffsets(Offsets);

			auto PauseMenuSlot = Cast<UCanvasPanelSlot>(PauseMenuCanvas.Slot);
			PauseMenuSlot.SetOffsets(FMargin(0, 0, 360, 0));

			if (!bIsAdded && bIsInDelayedRemove && Offsets.Left >= 0.0)
				FinishRemovingWidget();

			if (Offsets.Left <= -940.0)
				bFullyExpanded = true;
			else if (Offsets.Left >= -620.0)
				bFullyRetracted = true;

			auto GradientSlot = Cast<UCanvasPanelSlot>(GradientClippingBox.Slot);
			FMargin GradientOffsets = GradientSlot.GetOffsets();
			GradientOffsets.Left = 0.0;
			GradientOffsets.Right = Math::Clamp(960+Offsets.Left, 0, 360);
			GradientSlot.SetOffsets(GradientOffsets);

			float VisibleSize = Math::Clamp(-Offsets.Left, 600.0, 960.0);
			float Scale = 960.0 / VisibleSize;
			GradientImage.SetRenderScale(FVector2D(Scale, 1.0));
		}
		else
		{
			auto PlayerMenuSlot = Cast<UCanvasPanelSlot>(PlayerMenuCanvas.Slot);
			FMargin Offsets = PlayerMenuSlot.GetOffsets();
			if (!bIsAdded)
				PanelPosition.AccelerateToWithStop(-1000.0, 0.4, DeltaTime, 50.0);
			else if (CurrentState == EPauseMenuState::PauseMenu)
				PanelPosition.AccelerateToWithStop(-360.0, 0.4, DeltaTime, 50.0);
			else
				PanelPosition.AccelerateToWithStop(0.0, 0.4, DeltaTime, 50.0);
			Offsets.Left = PanelPosition.Value;
			PlayerMenuSlot.SetOffsets(Offsets);

			auto PauseMenuSlot = Cast<UCanvasPanelSlot>(PauseMenuCanvas.Slot);
			float PauseOffset = Math::Clamp(-Offsets.Left, 0, 360);
			PauseMenuSlot.SetOffsets(FMargin(PauseOffset, 0, 360 - PauseOffset, 0));

			if (!bIsAdded && bIsInDelayedRemove && Offsets.Left <= -960.0)
				FinishRemovingWidget();

			if (Offsets.Left >= -20.0)
				bFullyExpanded = true;
			else if (Offsets.Left <= -300.0)
				bFullyRetracted = true;

			auto GradientSlot = Cast<UCanvasPanelSlot>(GradientClippingBox.Slot);
			FMargin GradientOffsets = GradientSlot.GetOffsets();
			GradientOffsets.Left = Math::Clamp(-Offsets.Left, 0, 360);
			GradientOffsets.Right = 0.0;
			GradientSlot.SetOffsets(GradientOffsets);

			float VisibleSize = 960.0 + Math::Clamp(Offsets.Left, -360.0, 0.0);
			float Scale = 960.0 / VisibleSize;
			GradientImage.SetRenderScale(FVector2D(Scale, 1.0));
		}

		float PauseMenuTargetOpacity = 0.0;
		float OptionsMenuTargetOpacity = 0.0;
		float ChapterSelectTargetOpacity = 0.0;

		switch (CurrentState)
		{
			case EPauseMenuState::PauseMenu:
				if (bFullyRetracted)
					PauseMenuTargetOpacity = 1.0;
			break;
			case EPauseMenuState::OptionsMenu:
				if (bFullyExpanded)
					OptionsMenuTargetOpacity = 1.0;
			break;
			case EPauseMenuState::ChapterSelect:
				if (bFullyExpanded)
					ChapterSelectTargetOpacity = 1.0;
			break;
		}

		PauseMenuCanvas.RenderOpacity = Math::FInterpConstantTo(PauseMenuCanvas.RenderOpacity, PauseMenuTargetOpacity, DeltaTime, 20);
		ChapterSelectCanvas.RenderOpacity = Math::FInterpConstantTo(ChapterSelectCanvas.RenderOpacity, ChapterSelectTargetOpacity, DeltaTime, 20);
		OptionsMenuCanvas.RenderOpacity = Math::FInterpConstantTo(OptionsMenuCanvas.RenderOpacity, OptionsMenuTargetOpacity, DeltaTime, 20);

		// PauseMenuCanvas.RenderOpacity = PauseMenuTargetOpacity;
		// ChapterSelectCanvas.RenderOpacity = ChapterSelectTargetOpacity;
		// OptionsMenuCanvas.RenderOpacity = OptionsMenuTargetOpacity;

		if (bIsAdded)
			BackgroundContainer.RenderOpacity = Math::FInterpConstantTo(BackgroundContainer.RenderOpacity, 1.0, DeltaTime, 6.0);
		else
			BackgroundContainer.RenderOpacity = Math::FInterpConstantTo(BackgroundContainer.RenderOpacity, 0.0, DeltaTime, 12.0);
		InformationBoxesContainer.RenderOpacity = BackgroundContainer.RenderOpacity;

		bool bShowUnblurredGame = false;
		if (CurrentState == EPauseMenuState::OptionsMenu)
		{
			if (OptionsMenu.CurrentPage != nullptr && OptionsMenu.CurrentPage.bShowUnblurredGameInBackground)
				bShowUnblurredGame = true;
		}

		auto BackgroundSlot = Cast<UCanvasPanelSlot>(BackgroundContainer.Slot);
		
		FMargin BackgroundOffsets = BackgroundSlot.Offsets;
		FAnchors BackgroundAnchors = BackgroundSlot.Anchors;

		if (bShowUnblurredGame)
		{
			if (bIsRightPlayer)
			{
				BackgroundOffsets.Left = -955.0;
				BackgroundAnchors.Minimum.X = 1.0;
				BackgroundOffsets.Right = 955.0;
				BackgroundAnchors.Maximum.X = 1.0;
			}
			else
			{
				BackgroundOffsets.Right = 955.0;
				BackgroundAnchors.Maximum.X = 0.0;
			}
		}
		else
		{
			BackgroundOffsets.Left = 0.0;
			BackgroundOffsets.Right = 0.0;
			BackgroundAnchors.Minimum.X = 0.0;
			BackgroundAnchors.Maximum.X = 1.0;
		}

		BackgroundSlot.SetOffsets(BackgroundOffsets);
		BackgroundSlot.SetAnchors(BackgroundAnchors);
	}

	UPauseMenuButton GetFirstButton()
	{
		TArray<UWidget> Buttons;
		GetAllChildWidgetsOfClass(UPauseMenuButton, Buttons);

		for (auto Button : Buttons)
		{
			if (!Button.IsVisible())
				continue;
			return Cast<UPauseMenuButton>(Button);
		}

		return nullptr;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry MyGeometry, FFocusEvent InFocusEvent)
	{
		if (CurrentState == EPauseMenuState::PauseMenu)
		{
			// Focus the first button when we get focus
			if (LastFocusedButton != nullptr && LastFocusedButton.IsVisible())
				return FEventReply::Handled().SetUserFocus(LastFocusedButton, InFocusEvent.Cause);
			else
				return FEventReply::Handled().SetUserFocus(GetFirstButton(), InFocusEvent.Cause);
		}
		else if (CurrentState == EPauseMenuState::OptionsMenu)
		{
			// Focus the actual options menu
			return FEventReply::Handled().SetUserFocus(OptionsMenu, InFocusEvent.Cause);
		}
		else if (CurrentState == EPauseMenuState::ChapterSelect)
		{
			// Focus the actual options menu
			return FEventReply::Handled().SetUserFocus(ChapterSelect, InFocusEvent.Cause);
		}
		else
		{
			return FEventReply::Handled();
		}
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnAnalogValueChanged(FGeometry MyGeometry, FAnalogInputEvent InAnalogInputEvent)
	{
		if (CurrentState == EPauseMenuState::ChapterSelect)
			return FEventReply::Unhandled();

		if (IsPauseMenuHidden())
		{
			if (InAnalogInputEvent.Key == EKeys::Gamepad_LeftX
				|| InAnalogInputEvent.Key == EKeys::Gamepad_LeftY
				|| InAnalogInputEvent.Key == EKeys::Gamepad_RightX
				|| InAnalogInputEvent.Key == EKeys::Gamepad_RightY
			)
			{
				AHazePlayerCharacter ForPlayer = Lobby::GetPlayerForInput(InAnalogInputEvent.InputDeviceId);
				if (ForPlayer != nullptr)
				{
					FPauseMenuCameraData& Data = CameraData[ForPlayer];
					if (!Data.bControlled)
					{
						Data.Location = ForPlayer.ViewLocation;
						Data.ReferenceFrame = FTransform(FQuat::MakeFromZX(ForPlayer.MovementWorldUp, ForPlayer.ViewRotation.ForwardVector));
						Data.Rotation = Data.ReferenceFrame.InverseTransformRotation(ForPlayer.ViewRotation);
						Data.FieldOfView = ForPlayer.ViewFOV;
						Data.bControlled = true;
					}

					float Value = InAnalogInputEvent.AnalogValue;
					if (Math::Abs(Value) < 0.15)
						Value = 0.0;

					if (InAnalogInputEvent.Key == EKeys::Gamepad_LeftX)
						Data.LeftStick.X = Value;
					else if (InAnalogInputEvent.Key == EKeys::Gamepad_LeftY)
						Data.LeftStick.Y = Value;
					else if (InAnalogInputEvent.Key == EKeys::Gamepad_RightX)
						Data.RightStick.X = Value;
					else if (InAnalogInputEvent.Key == EKeys::Gamepad_RightY)
						Data.RightStick.Y = Value;
				}

				return FEventReply::Handled();
			}
		}

		if (InAnalogInputEvent.GetKey() == EKeys::Gamepad_RightY)
		{
			UAccessibilityChatWidget ChatWidget = UAccessibilityTextToSpeechSubsystem::Get().SpeechToTextChatWidget;
			if (ChatWidget != nullptr)
			{
				if (ChatWidget.BrowseInput(InAnalogInputEvent))
					return FEventReply::Handled();
			}
		}

		return FEventReply::Handled();
	}

	void UpdatePauseMenuCamera(EHazePlayer ForPlayer, float DeltaTime)
	{
		FPauseMenuCameraData& Data = CameraData[ForPlayer];
		if (!Data.bControlled)
			return;

		const FRotator RotationDelta = FRotator(
			Data.RightStick.Y * DeltaTime * 180.0,
			Data.RightStick.X * DeltaTime * 360.0,
			0.0);

		FRotator NewRotation = Data.Rotation + RotationDelta;
		NewRotation.Roll = 0.0;
		NewRotation.Pitch = Math::ClampAngle(NewRotation.Pitch, -89.0, 89.0);
		Data.Rotation = NewRotation;

		float Vertical = 0.0;
		if (Data.bHoldingUp)
			Vertical = 1.0;
		else if (Data.bHoldingDown)
			Vertical = -1.0;

		FQuat WorldRotation = Data.ReferenceFrame.TransformRotation(Data.Rotation).Quaternion();

		FVector MovementDirection = WorldRotation * FVector(Data.LeftStick.Y, Data.LeftStick.X, Vertical);
		FVector MovementDelta = MovementDirection * (2000 * DeltaTime) * Data.Speed;

		Data.Location += MovementDelta;
		Debug::OverridePlayerCameraView(ForPlayer, Data.Location, WorldRotation.Rotator(), Data.FieldOfView);
	}

	void RemovePauseMenuCameras()
	{
		for (auto ForPlayer : Game::Players)
		{
			if (CameraData[ForPlayer].bControlled)
			{
				CameraData[ForPlayer].bControlled = false;
				CameraData[ForPlayer].LeftStick = FVector2D();
				CameraData[ForPlayer].RightStick = FVector2D();
				CameraData[ForPlayer].bHoldingUp = false;
				CameraData[ForPlayer].bHoldingDown = false;
				CameraData[ForPlayer].Speed = 1.0;
				Debug::ClearPlayerCameraViewOverride(ForPlayer.Player);
			}
		}
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
	FEventReply OnKeyDown(FGeometry MyGeometry, FKeyEvent Event)
	{
		// If the console is up, don't eat the key input
		if (Console::IsConsoleActive() || Console::IsConsoleKey(Event.Key))
			return FEventReply::Unhandled();

		if (Event.Key == EKeys::Virtual_Back || Event.Key == EKeys::Escape
			|| Event.Key == EKeys::Gamepad_Special_Right)
		{
			bEscapeDown = true;
			return FEventReply::Handled();
		}
		
		if (CurrentState == EPauseMenuState::ChapterSelect)
		{
			// Don't eat navigation keys to they can be used for custom navigation later
			if (Event.Key == EKeys::Left || Event.Key == EKeys::Right || Event.Key == EKeys::Up || Event.Key == EKeys::Down
			|| Event.Key == EKeys::Gamepad_DPad_Left || Event.Key == EKeys::Gamepad_DPad_Right
			|| Event.Key == EKeys::Gamepad_DPad_Up || Event.Key == EKeys::Gamepad_DPad_Down)
			{
				return FEventReply::Unhandled();
			}

			if (Event.Key == EKeys::Enter || Event.Key == EKeys::Virtual_Accept)
			{
				OnChapterSelectProceedPressed();
				return FEventReply::Handled();
			}

			return FEventReply::Handled();
		}

		// Hide the pause menu with select if debug shortcuts are enabled
#if !RELEASE
		if (IsDevInputEnabled())
		{
			if (Event.Key == EKeys::Gamepad_Special_Left || Event.Key == EKeys::Y)
			{
				ToggleHidePauseMenu();
				return FEventReply::Handled();
			}

			if (IsPauseMenuHidden())
			{
				AHazePlayerCharacter ForPlayer = Lobby::GetPlayerForInput(Event.InputDeviceId);
				if (ForPlayer != nullptr)
				{
					if (Event.Key == EKeys::Gamepad_RightTrigger)
					{
						CameraData[ForPlayer].bHoldingUp = true;
						return FEventReply::Handled();
					}
					else if (Event.Key == EKeys::Gamepad_LeftTrigger)
					{
						CameraData[ForPlayer].bHoldingDown = true;
						return FEventReply::Handled();
					}
					else if (Event.Key == EKeys::Gamepad_RightShoulder)
					{
						CameraData[ForPlayer].Speed = Math::Min(CameraData[ForPlayer].Speed * 2.0, 64.0);
					}
					else if (Event.Key == EKeys::Gamepad_LeftShoulder)
					{
						CameraData[ForPlayer].Speed = Math::Max(CameraData[ForPlayer].Speed * 0.5, 1.0 / 64.0);
					}
				}
			}
		}
#endif


		return FEventReply::Handled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyUp(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		// If the console is up, don't eat the key input
		if (Console::IsConsoleActive() || Console::IsConsoleKey(InKeyEvent.Key))
			return FEventReply::Unhandled();

		if (InKeyEvent.Key == EKeys::Virtual_Back || InKeyEvent.Key == EKeys::Escape
			|| InKeyEvent.Key == EKeys::Gamepad_Special_Right)
		{
			if (bEscapeDown)
			{
				bEscapeDown = false;

				if (CurrentState != EPauseMenuState::PauseMenu && InKeyEvent.Key != EKeys::Gamepad_Special_Right)
					SwitchToState(EPauseMenuState::PauseMenu);
				else
					ClosePauseMenu();
			}
			return FEventReply::Handled();
		}

		if (CurrentState == EPauseMenuState::ChapterSelect)
		{
			return FEventReply::Handled();
		}

#if !RELEASE
		if (IsDevInputEnabled())
		{
			if (IsPauseMenuHidden())
			{
				AHazePlayerCharacter ForPlayer = Lobby::GetPlayerForInput(InKeyEvent.InputDeviceId);
				if (ForPlayer != nullptr)
				{
					if (InKeyEvent.Key == EKeys::Gamepad_RightTrigger)
						CameraData[ForPlayer].bHoldingUp = false;
					else if (InKeyEvent.Key == EKeys::Gamepad_LeftTrigger)
						CameraData[ForPlayer].bHoldingDown = false;
				}
			}
		}
#endif

		return FEventReply::Handled();
	}

	UFUNCTION(BlueprintOverride)
	UWidget OnCustomNavigation(FGeometry Geometry, FNavigationEvent Event, EUINavigationRule& OutRule)
	{
		if (CurrentState == EPauseMenuState::ChapterSelect)
		{
			// We respond to navigation here,
			// so analog stick can be used as well as dpad or keyboard.
			// We don't use the simulated buttons for the left stick,
			// because those are not nicely deadzoned.
			if (Event.NavigationType == EUINavigation::Left)
				ChapterSelect.NavigateGroupPrevious();
			if (Event.NavigationType == EUINavigation::Right)
				ChapterSelect.NavigateGroupNext();
			if (Event.NavigationType == EUINavigation::Up)
				ChapterSelect.NavigateItemPrevious();
			if (Event.NavigationType == EUINavigation::Down)
				ChapterSelect.NavigateItemNext();
		}

		return nullptr;
	}
};

class UPauseMenuButton : UMenuButtonWidget
{
	UPROPERTY(BindWidget)
	UMenuSelectionHighlight SelectionHighlight;

	UPROPERTY(BindWidget)
	UImage LineUp;
	UPROPERTY(BindWidget)
	UImage LineDown;

	UPROPERTY(BindWidget)
	UImage DotNormal;
	UPROPERTY(BindWidget)
	UImage DotSelected;

	UPROPERTY(BindWidget)
	UTextBlock ButtonText;

	UPROPERTY()
	UTexture2D TextureDotNormal_Neutral;
	UPROPERTY()
	UTexture2D TextureDotNormal_Mio;
	UPROPERTY()
	UTexture2D TextureDotNormal_Zoe;
	UPROPERTY()
	UTexture2D TextureDotActive_Neutral;
	UPROPERTY()
	UTexture2D TextureDotActive_Mio;
	UPROPERTY()
	UTexture2D TextureDotActive_Zoe;

	UPROPERTY(EditAnywhere, Category = "Pause Menu Button")
	bool bIsFirstOption = false;
	UPROPERTY(EditAnywhere, Category = "Pause Menu Button")
	bool bIsLastOption = false;

	UPROPERTY(EditAnywhere, Category = "Pause Menu Button")
	FText Text;

	bool bIsRightPlayer = false;

	UFUNCTION(BlueprintOverride)
	void PreConstruct(bool bIsDesignTime)
	{
		if (!Text.IsEmpty())
			ButtonText.SetText(Text);
		UpdateLine();
	}

	void UpdateLine()
	{
		if (bIsFirstOption)
			LineUp.Visibility = ESlateVisibility::Hidden;
		else
			LineUp.Visibility = ESlateVisibility::HitTestInvisible;

		if (bIsLastOption)
			LineDown.Visibility = ESlateVisibility::Hidden;
		else
			LineDown.Visibility = ESlateVisibility::HitTestInvisible;
	}

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		if (Game::HazeGameInstance != nullptr)
		{
			switch (Game::GetHazeGameInstance().GetPausingPlayer())
			{
				case EHazeSelectPlayer::Mio:
					DotNormal.SetBrushFromTexture(TextureDotNormal_Mio);
					DotSelected.SetBrushFromTexture(TextureDotActive_Mio);
				break;
				case EHazeSelectPlayer::Zoe:
					bIsRightPlayer = true;
					DotNormal.SetBrushFromTexture(TextureDotNormal_Zoe);
					DotSelected.SetBrushFromTexture(TextureDotActive_Zoe);
				break;
				default:
					DotNormal.SetBrushFromTexture(TextureDotNormal_Neutral);
					DotSelected.SetBrushFromTexture(TextureDotActive_Neutral);
				break;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (IsHoveredOrActive() || (LastPressedTime != 0 && Time::GetRealTimeSince(LastPressedTime) < 0.25))
		{
			SelectionHighlight.bIsHighlighted = true;
			DotSelected.Visibility = ESlateVisibility::Visible;
			DotNormal.Visibility = ESlateVisibility::Hidden;

			FSlateFontInfo FontInfo = ButtonText.Font;
			FontInfo.TypefaceFontName = n"Bold";
			ButtonText.SetFont(FontInfo);

			if (SelectionHighlight.bIsZoe || SelectionHighlight.bIsNeutral)
				ButtonText.SetColorAndOpacity(FLinearColor::Black);
		}
		else
		{
			SelectionHighlight.bIsHighlighted = false;
			DotSelected.Visibility = ESlateVisibility::Hidden;
			DotNormal.Visibility = ESlateVisibility::Visible;

			FSlateFontInfo FontInfo = ButtonText.Font;
			FontInfo.TypefaceFontName = NAME_None;
			ButtonText.SetFont(FontInfo);

			if (SelectionHighlight.bIsZoe || SelectionHighlight.bIsNeutral)
				ButtonText.SetColorAndOpacity(FLinearColor::White);
		}

		if (bPressed)
		{
			SelectionHighlight.SetRenderTranslation(FVector2D(3, 3));
			ButtonText.SetRenderTranslation(FVector2D(3, 3));
			DotSelected.SetRenderTranslation(FVector2D(3, 3));

			SetLineSize(LineUp, 26);
			SetLineSize(LineDown, 21);
		}
		else
		{
			SelectionHighlight.SetRenderTranslation(FVector2D(0, 0));
			ButtonText.SetRenderTranslation(FVector2D(0, 0));
			DotSelected.SetRenderTranslation(FVector2D(0, 0));

			SetLineSize(LineUp, 21);
			SetLineSize(LineDown, 21);
		}
	}

	void SetLineSize(UImage Image, int Size)
	{
		FSlateBrush Brush = Image.Brush;
		if (Brush.ImageSize.Y != Size)
		{
			Brush.ImageSize.Y = Size;
			Image.SetBrush(Brush);
		}
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry MyGeometry, FFocusEvent InFocusEvent)
	{
		auto PauseMenu = Cast<UPauseMenu>(GetParentWidgetOfClass(UPauseMenu));
		if (PauseMenu != nullptr)
			PauseMenu.LastFocusedButton = this;

		if (Game::IsNarrationEnabled())
			Game::NarrateText(Text);

		return Super::OnFocusReceived(MyGeometry, InFocusEvent);
	}
};

struct FPauseMenuCameraData
{
	bool bControlled = false;
	FVector Location;
	FTransform ReferenceFrame;
	FRotator Rotation;
	float FieldOfView;

	FVector2D LeftStick;
	FVector2D RightStick;

	float Speed = 1.0;

	bool bHoldingUp;
	bool bHoldingDown;
}