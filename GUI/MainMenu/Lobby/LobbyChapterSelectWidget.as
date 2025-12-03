UCLASS(Abstract)
class ULobbyChapterSelectWidget : ULobbyWidgetBase
{
	UPROPERTY(BindWidget)
	UChapterSelectWidget ChapterSelect;
	UPROPERTY(BindWidget)
	UMenuPromptOrButton BackButton;
	UPROPERTY(BindWidget)
	UMenuPromptOrButton ProceedButton;

	FKCodeHandler KCodeHandler;
	default bCustomNavigation = true;

	UHazeChapterDatabase ChapterDatabase;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
	}

	void OnTransitionEnter(EMainMenuState PreviousState, bool bSnap) override
	{
		Super::OnTransitionEnter(PreviousState, bSnap);

		ChapterDatabase = UHazeChapterDatabase::GetChapterDatabase();

		if (Lobby == nullptr)
			return;

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

		if (!Lobby.LobbyOwner.IsLocal())
		{
			// Guest players can't proceed
			ProceedButton.Visibility = ESlateVisibility::Collapsed;

			// Guest players disconnect when they go back here
			if (Lobby.Network != EHazeLobbyNetwork::Local)
			{
				BackButton.Text = NSLOCTEXT("MainMenuLobby", "DisconnectLobby", "Disconnect");
				BackButton.UpdateWidgets();
			}
		}
		else
		{
			ProceedButton.Visibility = ESlateVisibility::Visible;
		}

		ProceedButton.OnPressed.AddUFunction(this, n"ClickedProceed");
		BackButton.OnPressed.AddUFunction(this, n"ClickedBack");

		ChapterSelect.OnItemSelectionChanged.AddUFunction(this, n"OnItemSelectionChanged");

		ChapterSelect.bCanNavigate = Lobby.LobbyOwner.IsLocal();
		ChapterSelect.Refresh();

		if (Lobby.LobbyOwner.IsLocal())
		{
			// If we're already configured to do chapter select, keep that selection
			if (Lobby.StartType == EHazeLobbyStartType::ChapterSelect || Lobby.StartType == EHazeLobbyStartType::DevProgressPoint)
				UpdateSelectionFromLobby();
		}
		
		UpdateStartTypeInLobby();
	}

	UFUNCTION()
	private void OnItemSelectionChanged(ULobbyChapterSelectItemWidget Widget, FChapterSelectionItem Item)
	{
		UpdateStartTypeInLobby();
	}

	UFUNCTION()
	private void ClickedProceed(UHazeUserWidget Widget = nullptr)
	{
		ProceedGame();
	}

	UFUNCTION()
	private void ClickedBack(UHazeUserWidget Widget = nullptr)
	{
		if (Lobby.LobbyOwner.IsLocal())
		{
			Lobby::Menu_LobbySetState(EHazeLobbyState::ChooseStartType);
			MainMenu.GotoLobbyChooseStartType();
		}
		else
		{
			LeaveLobby();
		}
	}

	void UpdateStartTypeInLobby()
	{
		if (!Lobby.LobbyOwner.IsLocal())
			return;

		FChapterSelectionItem Item = ChapterSelect.GetSelectedItem();
		if (Item.ChapterRef.Name.IsEmpty())
			return;

		Lobby::Menu_LobbySelectStart(EHazeLobbyStartType::ChapterSelect, Item.ChapterRef, Item.ProgressPointRef);

		if (CanStartSelectedChapter())
		{
			FHazeChapter Chapter = ChapterDatabase.GetChapterByProgressPoint(Item.ChapterRef);
			FHazeChapterGroup ChapterGroup = ChapterDatabase.GetChapterGroup(Chapter);

			auto MioMesh = Chapter.OverridePlayerVariant_Mio;
			if (MioMesh.IsNull())
				MioMesh = ChapterGroup.PlayerVariant_Mio;

			auto ZoeMesh = Chapter.OverridePlayerVariant_Zoe;
			if (ZoeMesh.IsNull())
				ZoeMesh = ChapterGroup.PlayerVariant_Zoe;

			MainMenu.SetCharacterMeshVariants(MioMesh, Chapter.OverridePlayerIdleAnimation_Mio, ZoeMesh, Chapter.OverridePlayerIdleAnimation_Zoe);
		}
		else
		{
			MainMenu.SetDefaultCharacterMeshVariants();
		}
	}

	void UpdateSelectionFromLobby()
	{
		bool bSelectionChanged = ChapterSelect.SetSelectedItem(
			Lobby.StartChapter,
			Lobby.StartProgressPoint,
		);

		if (bSelectionChanged)
			ChapterSelect.ScrollToSelectedItem();

		if (!Lobby.LobbyOwner.IsLocal())
		{
			FHazeChapter Chapter = ChapterDatabase.GetChapterByProgressPoint(Lobby.StartChapter);
			FHazeChapterGroup ChapterGroup = ChapterDatabase.GetChapterGroup(Chapter);

			auto MioMesh = Chapter.OverridePlayerVariant_Mio;
			if (MioMesh.IsNull())
				MioMesh = ChapterGroup.PlayerVariant_Mio;

			auto ZoeMesh = Chapter.OverridePlayerVariant_Zoe;
			if (ZoeMesh.IsNull())
				ZoeMesh = ChapterGroup.PlayerVariant_Zoe;

			MainMenu.SetCharacterMeshVariants(MioMesh, Chapter.OverridePlayerIdleAnimation_Mio, ZoeMesh, Chapter.OverridePlayerIdleAnimation_Zoe);
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
			ChapterSelect.NavigateGroupPrevious();
		if (Event.NavigationType == EUINavigation::Right)
			ChapterSelect.NavigateGroupNext();
		if (Event.NavigationType == EUINavigation::Up)
			ChapterSelect.NavigateItemPrevious();
		if (Event.NavigationType == EUINavigation::Down)
			ChapterSelect.NavigateItemNext();

		return nullptr;
	}

	UFUNCTION(BlueprintPure)
	bool CanStartSelectedChapter()
	{
		if (Lobby == nullptr)
			return false;
		if (!Lobby.LobbyOwner.IsLocal())
			return true;

		switch (Lobby.StartType)
		{
			case EHazeLobbyStartType::NewGame:
				return true;
			case EHazeLobbyStartType::ChapterSelect:
			{
				if (!Save::IsContinueStartable(Lobby.StartChapter, Lobby.StartProgressPoint))
					return false;

				FHazeChapter Chapter = ChapterDatabase.GetChapterByProgressPoint(Lobby.StartChapter);
				if (Chapter.bIsSideContent)
				{
					if (!Save::IsSideContentUnlocked(Chapter.ProgressPoint))
						return false;
				}

				return true;
			}
			case EHazeLobbyStartType::Continue:
				return Save::IsContinueStartable(Lobby.StartChapter, Lobby.StartProgressPoint);
			default:
			break;
		}

		return false;
	}

	UFUNCTION()
	void ProceedGame()
	{
		if (CanStartSelectedChapter())
			Lobby::Menu_LobbySetState(EHazeLobbyState::CharacterSelect);
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

		// Don't eat navigation keys to they can be used for custom navigation later
		if (Event.Key == EKeys::Left || Event.Key == EKeys::Right || Event.Key == EKeys::Up || Event.Key == EKeys::Down
		 || Event.Key == EKeys::Gamepad_DPad_Left || Event.Key == EKeys::Gamepad_DPad_Right
		 || Event.Key == EKeys::Gamepad_DPad_Up || Event.Key == EKeys::Gamepad_DPad_Down)
		{
			return FEventReply::Unhandled();
		}

		if (Event.Key == EKeys::Gamepad_LeftShoulder)
		{
			ChapterSelect.NavigateGroupPrevious();
			return FEventReply::Handled();
		}

		if (Event.Key == EKeys::Gamepad_RightShoulder)
		{
			ChapterSelect.NavigateGroupNext();
			return FEventReply::Handled();
		}

		if (Event.Key == EKeys::Escape || Event.Key == EKeys::Virtual_Back)
		{
			if (Lobby.LobbyOwner.IsLocal())
			{
				Lobby::Menu_LobbySetState(EHazeLobbyState::ChooseStartType);
				MainMenu.GotoLobbyChooseStartType();
				return FEventReply::Handled();
			}
		}

		// Proceed to character select from chapter select
		if (Event.Key == EKeys::Enter
			|| Event.Key == EKeys::Virtual_Accept)
		{
			if (Lobby.LobbyOwner.IsLocal()
				&& Lobby.NumIdentitiesInLobby() >= 2)
			{
				ProceedGame();
				//GetAudioManager().UI_ProceedToCharacterSelect();
				return FEventReply::Handled();
			}
		}
		
		return Super::OnKeyDown(Geom, Event);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geom, float Timer)
	{
		Super::Tick(Geom, Timer);

		if (Lobby == nullptr)
			return;

		if (!Lobby.LobbyOwner.IsLocal())
		{
			UpdateSelectionFromLobby();
		}
		else
		{
			if (CanStartSelectedChapter())
				ProceedButton.bDisabled = false;
			else
				ProceedButton.bDisabled = true;
		}
	}
};

struct FKCodeHandler
{
	int Progress = -1;

	bool AddInput(UWidget Widget, FKey Key)
	{
		bool bCanProceed = false;
		bool bShouldEat = false;

		switch (Progress+1)
		{
			case 0:
			case 1:
				bCanProceed = (Key == EKeys::Up) || (Key == EKeys::Gamepad_DPad_Up);
			break;
			case 2:
			case 3:
				bCanProceed = (Key == EKeys::Down) || (Key == EKeys::Gamepad_DPad_Down);
			break;
			case 4:
			case 6:
				bCanProceed = (Key == EKeys::Left) || (Key == EKeys::Gamepad_DPad_Left);
			break;
			case 5:
			case 7:
				bCanProceed = (Key == EKeys::Right) || (Key == EKeys::Gamepad_DPad_Right);
			break;
			case 8:
				bCanProceed = (Key == EKeys::B) || (Key == EKeys::Gamepad_FaceButton_Right);
				bShouldEat = true;
			break;
			case 9:
				bCanProceed = (Key == EKeys::A) || (Key == EKeys::Gamepad_FaceButton_Bottom);
				bShouldEat = true;
			break;
		}

		if (bCanProceed)
			Progress += 1;
		else if (Progress != -1)
			Progress = -1;

		if (Progress >= 9)
		{
			PrintToScreen("Good Morning World!", Duration = 5.f, Color = FLinearColor::Green);
			Console::ExecuteConsoleCommand("Haze.UnlockAllChapters");
			Console::ExecuteConsoleCommand("Haze.UnlockAllSideContent");

			FHazeProgressPointRef ContinueChapter;
			FHazeProgressPointRef ContinuePoint;
			bool bHasContinue = Save::GetContinueProgress(ContinueChapter, ContinuePoint);
			if (!bHasContinue)
			{
				auto ChapterDatabase = UHazeChapterDatabase::GetChapterDatabase();
				Save::SaveAtProgressPoint(Progress::GetProgressPointRefID(ChapterDatabase.InitialChapter), true);
			}

			auto LobbyChapterSelect = Cast<ULobbyChapterSelectWidget>(Widget);
			if (LobbyChapterSelect != nullptr)
			{
				LobbyChapterSelect.ChapterSelect.GenerateChapterSelectionItems();
				LobbyChapterSelect.ChapterSelect.RefreshItemWidgets();
			}

			auto LobbyChooseStartType = Cast<ULobbyChooseStartTypeWidget>(Widget);
			if (LobbyChooseStartType != nullptr)
			{
				LobbyChooseStartType.UpdateAvailableButtons();
			}
		}

		return bShouldEat;
	}
};

class ULobbyChapterSelectItemWidget : UChapterSelectItemWidget
{
}