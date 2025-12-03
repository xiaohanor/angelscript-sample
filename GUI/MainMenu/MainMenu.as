

enum EMainMenuState
{
	None,
	Splash,
	MainMenu,
	LobbyPlayers,
	LobbyChooseStartType,
	LobbyChapterSelect,
	LobbyCharacterSelect,
	LobbyCrossplay,
	LocalWireless,
	Options,
	BusyTask,
	Credits,
	MAX
};

struct FMainMenuStateCameraInfo
{
	UPROPERTY()
	AStaticCameraActor Camera;
	UPROPERTY()
	float BlendInTime = 2.0;
};

const FConsoleVariable CVar_PreloadOnMainMenu("Haze.PreloadOnMainMenu", 1);
const FConsoleVariable CVar_MainMenuDebugBusyTask("Haze.MainMenuDebugBusyTask", 0);

event void FOnPlayOpeningCutscene();

class AMainMenu : AHazeActor
{
	default PrimaryActorTick.bTickEvenWhenPaused = true;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	// Widget classes that should be shown for each main menu state
	UPROPERTY(EditAnywhere, Meta = (ArraySizeEnum = "/Script/Angelscript.EMainMenuState"))
	TArray<TSubclassOf<UMainMenuStateWidget>> StateWidgets;
	default StateWidgets.SetNum(EMainMenuState::MAX);

	// Cameras to use for each main menu state
	UPROPERTY(EditAnywhere, Meta = (ArraySizeEnum = "/Script/Angelscript.EMainMenuState"))
	TArray<FMainMenuStateCameraInfo> StateCameras;
	default StateCameras.SetNum(EMainMenuState::MAX);

	UPROPERTY()
	TSubclassOf<UMainMenuBackgroundWidget> MenuBackgroundWidget;

	UMainMenuStateWidget ActiveWidget;
	EMainMenuState ActiveState = EMainMenuState::None;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	UHazePlayerIdentity OwnerIdentity;

	UPROPERTY()
	FOnPlayOpeningCutscene OnPlayOpeningCutscene;

	UPROPERTY(BlueprintReadOnly, EditAnywhere)
	TSubclassOf<USubtitleWidget> SubtitleWidget;

	UPROPERTY()
	AMenuCameraUser CameraUser;
	UPROPERTY()
	ASecondaryMenuCameraUser SecondaryCameraUser;

	UPROPERTY(EditAnywhere)
	AChapterSelectPlayerMesh ChapterSelectMesh_Mio;
	UPROPERTY(EditAnywhere)
	AChapterSelectPlayerMesh ChapterSelectMesh_Zoe;

	UPROPERTY(EditAnywhere)
	AActor NewGameCharacterSelectRoot;

	UPROPERTY()
	USkeletalMesh DefaultMioMesh;
	UPROPERTY()
	USkeletalMesh DefaultZoeMesh;
	UPROPERTY()
	UAnimSequence DefaultMioAnimation;
	UPROPERTY()
	UAnimSequence DefaultZoeAnimation;

	UPROPERTY(EditAnywhere, Category="Sounds")
	FSoundDefReference SoundDefReference;

	UMainMenuSkipCutsceneOverlay SkipCutsceneOverlay;
	
	private EHazeRichPresence AppliedRichPresence = EHazeRichPresence::MainMenu;
	private AStaticCameraActor CurrentCamera;
	private bool bIsPreloading = false;
	private bool bHasCamera = false;
	private TSoftObjectPtr<USkeletalMesh> ActiveMioMesh;
	private TSoftObjectPtr<UAnimSequence> ActiveMioAnimation;
	private TSoftObjectPtr<USkeletalMesh> ActiveZoeMesh;
	private TSoftObjectPtr<UAnimSequence> ActiveZoeAnimation;
	private UMainMenuBackgroundWidget BackgroundWidget;
	bool bIsFadingOutCamera = false;
	bool bIsFadingCamera = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CameraUser = AMenuCameraUser::Spawn();
		SecondaryCameraUser = ASecondaryMenuCameraUser::Spawn();
		CameraUser.AdditionalSecondaryCameraUser = SecondaryCameraUser;

		// Assign widget class for subtitles
		CameraUser.SubtitleComponent.SubtitleWidget = SubtitleWidget;
		SecondaryCameraUser.SubtitleComponent.SubtitleWidget = SubtitleWidget;

		// Attach to persistent actor.
		Menu::AttachSoundDef(SoundDefReference, this);

		// Clear rich presence when we enter the main menu on PC
		// Don't do this on console because we won't have engaged a user yet
		if (!Game::IsConsoleBuild())
			Online::UpdateRichPresence(EHazeRichPresence::MainMenu);
	}

	bool IsOwnerInput(FKeyEvent Event)
	{
		if (OwnerIdentity == nullptr)
			return false;
		return OwnerIdentity.TakesInputFromController(Event.InputDeviceId);
	}

	bool IsInvalidInput(FKeyEvent Event)
	{
		auto Identity = Online::GetLocalIdentityAssociatedWithInputDevice(Event.InputDeviceId);
		return Identity == nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		if (ActiveState != EMainMenuState::None)
			CloseMainMenu();

		Widget::SetFocusToGameViewport();
		Menu::RemoveSoundDef(SoundDefReference, this);

		if (Game::HazeGameInstance.bAllowPauseOnMainMenu)
		{
			Game::HazeGameInstance.bAllowPauseOnMainMenu = false;
			Game::HazeGameInstance.ClosePauseMenu();
		}
	}

	void CloseMainMenu()
	{
		// Destroy all menu widgets when moving away from the main menu
		if (ActiveWidget != nullptr)
		{
			Widget::RemoveFullscreenWidget(ActiveWidget);
			ActiveWidget = nullptr;
		}

		if (BackgroundWidget != nullptr)
		{
			Widget::RemoveFullscreenWidget(BackgroundWidget);
			BackgroundWidget = nullptr;
		}

#if !EDITOR
		StateWidgets.Empty();
#endif

		// We don't reset the online system's primary identity here,
		// because we could be closing the menu and going in-game.
		// Primary identity will be reset the next time we go to splash.
		OwnerIdentity = nullptr;

		// Make sure the game is focused after we leave the menu
		Widget::SetUseMouseCursor(this, false);
		Widget::SetFocusToGameViewport();
		ActiveState = EMainMenuState::None;
	}

	bool IsInLobby()
	{
		return ActiveState == EMainMenuState::LobbyPlayers
			|| ActiveState == EMainMenuState::LobbyChapterSelect
			|| ActiveState == EMainMenuState::LobbyChooseStartType
			|| ActiveState == EMainMenuState::LobbyCharacterSelect
			|| ActiveState == EMainMenuState::LobbyCrossplay;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		UpdateMainMenuRichPresence();
		UpdateLevelPreload();
		UpdateMenuBackgroundWidget(DeltaTime);

		// Don't do anything if the menu isn't shown at all
		if (ActiveState == EMainMenuState::None)
			return;

		// Busy task text from the online system always has precedence if we have a OwnerIdentity
		if (HasBusyTask() && OwnerIdentity != nullptr)
		{
			if (ActiveState != EMainMenuState::BusyTask)
				SwitchToState(EMainMenuState::BusyTask, bSnap=false);
		}
		// Return to splash if our primary identity is different from the menu owner
		else if (Online::PrimaryIdentity != OwnerIdentity && Online::PrimaryIdentity != nullptr && OwnerIdentity != nullptr)
		{
			Lobby::Menu_LeaveLobby();
			ReturnToSplashScreen(Online::PrimaryIdentity, true);
		}
		else if (ActiveState != EMainMenuState::Splash)
		{
			// Back to main menu from busy task
			if (ActiveState == EMainMenuState::BusyTask)
			{
				if (OwnerIdentity != nullptr)
					SwitchToState(EMainMenuState::MainMenu, bSnap=false);
				else
					SwitchToState(EMainMenuState::Splash, bSnap=false);
			}

			// If the lobby game has started, always close the menu
			auto Lobby = Lobby::GetLobby();
			if (Lobby != nullptr && Lobby.HasGameStarted())
			{
				CloseMainMenu();
				return;
			}

			// If a lobby is up, always be in the lobby state
			if (!IsInLobby() && Lobby != nullptr && !Lobby.HasGameStarted())
			{
				SwitchToState(EMainMenuState::LobbyPlayers, bSnap=false);
			}

			// We can never be in the lobby state without a lobby being up
			if (IsInLobby() && Lobby == nullptr)
				SwitchToState(EMainMenuState::MainMenu, bSnap=false);
		}

		if (!IsMessageDialogShown() && !DemoUpsell::IsDemoUpsellActive() && !Game::IsPausedByPlayer())
		{
			if (ActiveWidget != nullptr && Widget::IsAnyUserFocusGameViewportOrNone())
			{
				Widget::SetAllPlayerUIFocusBeneathParent(ActiveWidget);
			}
		}

		// Update the overlay widget when we're playing a cutscene
		// this captures skip input
		if (CameraUser.ActiveLevelSequenceActor != nullptr && !Game::IsPausedByPlayer())
		{
			if (SkipCutsceneOverlay == nullptr)
			{
				SkipCutsceneOverlay = Cast<UMainMenuSkipCutsceneOverlay>(Widget::AddFullscreenWidget(
					UMainMenuSkipCutsceneOverlay,
					EHazeWidgetLayer::Menu
				));
				SkipCutsceneOverlay.CameraUser = CameraUser;
				if (!IsMessageDialogShown())
					Widget::SetAllPlayerUIFocus(SkipCutsceneOverlay);
			}

			if (!Widget::IsSlateUserFocusOutsideGame(0) && !IsMessageDialogShown())
				Widget::SetAllPlayerUIFocus(SkipCutsceneOverlay);
		}
		else
		{
			if (SkipCutsceneOverlay != nullptr)
			{
				Widget::RemoveFullscreenWidget(SkipCutsceneOverlay);
				SkipCutsceneOverlay = nullptr;
			}
		}

		if (CameraUser.ActiveLevelSequenceActor != nullptr)
		{
			Game::HazeGameInstance.bAllowPauseOnMainMenu = true;
		}
		else
		{
			Game::HazeGameInstance.bAllowPauseOnMainMenu = false;
			Game::HazeGameInstance.ClosePauseMenu();
		}
	}

	void UpdateMenuBackgroundWidget(float DeltaTime)
	{
		if (BackgroundWidget == nullptr)
			return;

		if (ActiveWidget == nullptr || !ActiveWidget.bShowMenuBackground || CameraUser.GetActiveLevelSequenceActor() != nullptr)
		{
			if (!bIsFadingOutCamera)
			{
				float InterpSpeed = 5.0;
				if (CameraUser.GetActiveLevelSequenceActor() != nullptr)
					InterpSpeed = 2.0;
				BackgroundWidget.SetRenderOpacity(Math::FInterpConstantTo(BackgroundWidget.GetRenderOpacity(), 0.0, DeltaTime, InterpSpeed));
				if (BackgroundWidget.GetRenderOpacity() <= 0.0)
					BackgroundWidget.MenuTitle.SetRenderOpacity(1.0);
			}
		}
		else
		{
			if (bIsFadingCamera && !bIsFadingOutCamera)
				BackgroundWidget.SetRenderOpacity(Math::FInterpConstantTo(BackgroundWidget.GetRenderOpacity(), 1.0, DeltaTime, 4.0));
			else
				BackgroundWidget.SetRenderOpacity(Math::Max(ActiveWidget.GetRenderOpacity(), BackgroundWidget.GetRenderOpacity()));

			BackgroundWidget.SetMenuTitle(ActiveWidget.MenuBackgroundTitle);
			BackgroundWidget.SetShowButtonBar(ActiveWidget.bShowButtonBarBackground);

			if (ActiveWidget.MenuBackgroundTitle.IsEmpty())
				BackgroundWidget.MenuTitle.SetRenderOpacity(Math::FInterpConstantTo(BackgroundWidget.MenuTitle.GetRenderOpacity(), 0.0, DeltaTime, 4.0));
			else
				BackgroundWidget.MenuTitle.SetRenderOpacity(Math::FInterpConstantTo(BackgroundWidget.MenuTitle.GetRenderOpacity(), 1.0, DeltaTime, 2.0));
		}
	}

	bool CanSwitchToState(EMainMenuState NewState)
	{
		// Only allow switching back to splash if our primary identity doesn't match
		if (Online::PrimaryIdentity != OwnerIdentity)
		{
			if (NewState != EMainMenuState::Splash)
				return false;
		}
		return true;
	}

	UFUNCTION()
	void ReturnToMainMenu(bool bSnap = false)
	{
		if (!CanSwitchToState(EMainMenuState::MainMenu))
			return;
		SwitchToState(EMainMenuState::MainMenu, bSnap);
	}

	UFUNCTION()
	void GotoLobbyPlayers()
	{
		if (ActiveState == EMainMenuState::LobbyPlayers)
			return;
		if (!CanSwitchToState(EMainMenuState::LobbyPlayers))
			return;
		SwitchToState(EMainMenuState::LobbyPlayers, bSnap = false);
	}

	UFUNCTION()
	void GotoLobbyChooseStartType()
	{
		if (ActiveState == EMainMenuState::LobbyChooseStartType)
			return;
		if (!CanSwitchToState(EMainMenuState::LobbyChooseStartType))
			return;
		SwitchToState(EMainMenuState::LobbyChooseStartType, bSnap = false);
	}

	UFUNCTION()
	void GotoLobbyCrossplay()
	{
		if (ActiveState == EMainMenuState::LobbyCrossplay)
			return;
		if (!CanSwitchToState(EMainMenuState::LobbyCrossplay))
			return;
		SwitchToState(EMainMenuState::LobbyCrossplay, bSnap = false);
	}

	UFUNCTION()
	void GotoChapterSelect()
	{
		if (ActiveState == EMainMenuState::LobbyChapterSelect)
			return;
		if (!CanSwitchToState(EMainMenuState::LobbyChapterSelect))
			return;
		SwitchToState(EMainMenuState::LobbyChapterSelect, bSnap = false);
	}

	UFUNCTION()
	void GotoCharacterSelect()
	{
		if (ActiveState == EMainMenuState::LobbyCharacterSelect)
			return;
		if (!CanSwitchToState(EMainMenuState::LobbyCharacterSelect))
			return;
		SwitchToState(EMainMenuState::LobbyCharacterSelect, bSnap = false);
	}

	UFUNCTION()
	void GotoLocalWireless()
	{
		if (ActiveState == EMainMenuState::LocalWireless)
			return;
		if (!CanSwitchToState(EMainMenuState::LocalWireless))
			return;
		SwitchToState(EMainMenuState::LocalWireless, bSnap = false);
	}

	UFUNCTION()
	void ShowOptionsMenu()
	{
		if (!CanSwitchToState(EMainMenuState::Options))
			return;
		SwitchToState(EMainMenuState::Options, bSnap = false);
	}

	UFUNCTION()
	void ShowCredits()
	{
		if (!CanSwitchToState(EMainMenuState::Credits))
			return;
		SwitchToState(EMainMenuState::Credits, bSnap = false);
	}

	UFUNCTION()
	void ReturnToSplashScreen(UHazePlayerIdentity WithIdentity = nullptr, bool bSnap = false)
	{
		if (!CanSwitchToState(EMainMenuState::Splash))
			return;
		OwnerIdentity = nullptr;
		Online::SetPrimaryIdentity(WithIdentity);
		SwitchToState(EMainMenuState::Splash, bSnap = bSnap);
	}

	UFUNCTION()
	void ConfirmMenuOwner(UHazePlayerIdentity Identity, bool bSnap = false)
	{
		check(ActiveState == EMainMenuState::Splash);
		check(OwnerIdentity == nullptr);

		GameSettings::SetGameSettingsProfile(Identity);
		OwnerIdentity = Identity;
		Online::SetPrimaryIdentity(OwnerIdentity);
		SwitchToState(EMainMenuState::MainMenu, bSnap);
		Online::UpdateRichPresence(EHazeRichPresence::MainMenu);
	}

	private void SwitchToState(EMainMenuState NewState, bool bSnap)
	{
		if (!CanSwitchToState(NewState))
			return;

		auto PreviousState = ActiveState;

		if (ActiveWidget != nullptr)
		{
			ActiveWidget.OnTransitionExit(NewState, bSnap);
			Widget::RemoveFullscreenWidget(ActiveWidget);
			if (!IsMessageDialogShown() && !DemoUpsell::IsDemoUpsellActive())
				Widget::DisableAllPlayerUIFocus();
			ActiveWidget = nullptr;
		}

		ActiveState = NewState;
		bIsFadingCamera = false;
		bIsFadingOutCamera = false;

		ActiveWidget = Cast<UMainMenuStateWidget>(
			Widget::AddFullscreenWidget(
				StateWidgets[int(ActiveState)],
				EHazeWidgetLayer::Menu
			)
		);
		ActiveWidget.MainMenu = this;
		ActiveWidget.SetWidgetZOrderInLayer(-100);

		UMenuEffectEventHandler::Trigger_OnMenuStateChanged(Menu::GetAudioActor(), FMainMenuStateChangeData(ActiveWidget, ActiveState));

		if (!IsMessageDialogShown() && !DemoUpsell::IsDemoUpsellActive())
			Widget::SetAllPlayerUIFocus(ActiveWidget);

		ActiveWidget.OnTransitionEnter(PreviousState, bSnap);

		EMainMenuState CameraState = ActiveState;
		if (CameraState == EMainMenuState::Splash)
		{
			CameraState = EMainMenuState::MainMenu;
		}
		else if (CameraState == EMainMenuState::LobbyCharacterSelect)
		{
			// Use the chapter select camera if we're not coming out of the new game cutscene
			if (Lobby::GetLobby() != nullptr && Lobby::GetLobby().StartType != EHazeLobbyStartType::NewGame)
				CameraState = EMainMenuState::LobbyChapterSelect;
		}

		if (StateCameras.IsValidIndex(int(CameraState)))
		{
			auto& CameraInfo = StateCameras[int(CameraState)];
			if (CameraInfo.Camera != nullptr
				&& CameraUser.ActiveCamera != CameraInfo.Camera.Camera)
			{
				bool bShouldFade = false;
				if (CameraUser.ActiveCamera != nullptr)
				{
					if (CameraUser.ActiveCamera.HasTag(n"CharacterSelectCamera") != CameraInfo.Camera.Camera.HasTag(n"CharacterSelectCamera"))
						bShouldFade = true;
					if (CameraUser.ActiveCamera.HasTag(n"ChapterSelectCamera") != CameraInfo.Camera.Camera.HasTag(n"ChapterSelectCamera"))
						bShouldFade = true;
				}

				if (bShouldFade && CameraUser.GetActiveLevelSequenceActor() == nullptr)
				{
					bIsFadingCamera = true;
					bIsFadingOutCamera = true;
					CameraUser.AddTemporaryFade(0.25, 0.25, 0.25);
					Timer::SetTimer(this, n"OnCameraFadedOut", 0.25);
					Timer::SetTimer(this, n"OnCameraFadedIn", 0.5);

					// Notify audio
					auto EventsCameraInfo = FMainMenuStateCameraInfo();
					EventsCameraInfo.BlendInTime = 0.25;
					EventsCameraInfo.Camera = CameraInfo.Camera;
					UMenuEffectEventHandler::Trigger_OnCameraTransition(Menu::GetAudioActor(), FMainMenuCameraTransition(EMainMenuCameraTransitionType::Fade, EventsCameraInfo));
				}
				else
				{
					if (bHasCamera)
					{
						UMenuEffectEventHandler::Trigger_OnCameraTransition(Menu::GetAudioActor(), FMainMenuCameraTransition(EMainMenuCameraTransitionType::BlendTo, CameraInfo));
						CameraUser.BlendToCamera(CameraInfo.Camera, CameraInfo.BlendInTime);
					}
					else
					{
						UMenuEffectEventHandler::Trigger_OnCameraTransition(Menu::GetAudioActor(), FMainMenuCameraTransition(EMainMenuCameraTransitionType::SnapTo, CameraInfo));
						CameraUser.SnapToCamera(CameraInfo.Camera);
					}

					bHasCamera = true;
					UpdateChapterSelectMeshVisibility();
				}
			}
			else
			{
				UpdateChapterSelectMeshVisibility();
			}
		}

		if (bSnap)
		{
			UpdateChapterSelectMeshVisibility();
			if (ActiveWidget.bShowMenuBackground)
				BackgroundWidget.SetRenderOpacity(1.0);
			else
				BackgroundWidget.SetRenderOpacity(0.0);
		}
	}

	void UpdateChapterSelectMeshVisibility()
	{
		if (ActiveState == EMainMenuState::LobbyChapterSelect)
		{
			if (ChapterSelectMesh_Mio != nullptr)
				ChapterSelectMesh_Mio.SetActorHiddenInGame(false);
			if (ChapterSelectMesh_Zoe != nullptr)
				ChapterSelectMesh_Zoe.SetActorHiddenInGame(false);
			if (NewGameCharacterSelectRoot != nullptr)
				NewGameCharacterSelectRoot.RootComponent.SetHiddenInGame(true, true);
		}
		else if (ActiveState == EMainMenuState::LobbyCharacterSelect)
		{
			if (Lobby::GetLobby() != nullptr
				&& Lobby::GetLobby().StartType == EHazeLobbyStartType::NewGame)
			{
				if (CameraUser.ActiveLevelSequenceActor != nullptr)
				{
					if (NewGameCharacterSelectRoot != nullptr)
						NewGameCharacterSelectRoot.RootComponent.SetHiddenInGame(true, true);
				}
				else
				{
					if (NewGameCharacterSelectRoot != nullptr)
						NewGameCharacterSelectRoot.RootComponent.SetHiddenInGame(false, true);
				}

				if (ChapterSelectMesh_Mio != nullptr)
					ChapterSelectMesh_Mio.SetActorHiddenInGame(true);
				if (ChapterSelectMesh_Zoe != nullptr)
					ChapterSelectMesh_Zoe.SetActorHiddenInGame(true);
			}
			else
			{
				if (ChapterSelectMesh_Mio != nullptr)
					ChapterSelectMesh_Mio.SetActorHiddenInGame(false);
				if (ChapterSelectMesh_Zoe != nullptr)
					ChapterSelectMesh_Zoe.SetActorHiddenInGame(false);
				if (NewGameCharacterSelectRoot != nullptr)
					NewGameCharacterSelectRoot.RootComponent.SetHiddenInGame(true, true);
			}
		}
		else
		{
			if (ChapterSelectMesh_Mio != nullptr)
				ChapterSelectMesh_Mio.SetActorHiddenInGame(true);
			if (ChapterSelectMesh_Zoe != nullptr)
				ChapterSelectMesh_Zoe.SetActorHiddenInGame(true);
			if (NewGameCharacterSelectRoot != nullptr)
				NewGameCharacterSelectRoot.RootComponent.SetHiddenInGame(true, true);
		}
	}

	UFUNCTION()
	private void OnCameraFadedIn()
	{
		bIsFadingCamera = false;
	}

	void SetDefaultCharacterMeshVariants()
	{
		SetCharacterMeshVariants(
			DefaultMioMesh,
			DefaultMioAnimation,
			DefaultZoeMesh,
			DefaultZoeAnimation,
		);
	}

	void SetCharacterMeshVariants(
		TSoftObjectPtr<USkeletalMesh> InMioMesh,
		TSoftObjectPtr<UAnimSequence> InMioAnimation,
		TSoftObjectPtr<USkeletalMesh> InZoeMesh,
		TSoftObjectPtr<UAnimSequence> InZoeAnimation,
	)
	{
		TSoftObjectPtr<USkeletalMesh> MioMesh = InMioMesh;
		if (MioMesh.IsNull())
			MioMesh = DefaultMioMesh;

		TSoftObjectPtr<UAnimSequence> MioAnimation = InMioAnimation;
		if (MioAnimation.IsNull())
			MioAnimation = DefaultMioAnimation;
		if (MioAnimation != ActiveMioAnimation)
			ActiveMioAnimation.Reset();

		bool bLoadMioMesh = false;
		bool bLoadMioAnimation = false;
		bool bLoadZoeMesh = false;
		bool bLoadZoeAnimation = false;

		if (MioMesh != ActiveMioMesh)
		{
			ActiveMioMesh = MioMesh;
			bLoadMioMesh = true;
		}

		if (MioAnimation != ActiveMioAnimation)
		{
			ActiveMioAnimation = MioAnimation;
			bLoadMioAnimation = true;
		}

		TSoftObjectPtr<USkeletalMesh> ZoeMesh = InZoeMesh;
		if (ZoeMesh.IsNull())
			ZoeMesh = DefaultZoeMesh;

		TSoftObjectPtr<UAnimSequence> ZoeAnimation = InZoeAnimation;
		if (ZoeAnimation.IsNull())
			ZoeAnimation = DefaultZoeAnimation;
		if (ZoeAnimation != ActiveZoeAnimation)
			ActiveZoeAnimation.Reset();

		if (ZoeMesh != ActiveZoeMesh)
		{
			ActiveZoeMesh = ZoeMesh;
			bLoadZoeMesh = true;
		}

		if (ZoeAnimation != ActiveZoeAnimation)
		{
			ActiveZoeAnimation = ZoeAnimation;
			bLoadZoeAnimation = true;
		}

		if (bLoadMioMesh)
			ActiveMioMesh.LoadAsync(FOnSoftObjectLoaded(this, n"OnPlayerVariantLoaded"));
		if (bLoadZoeMesh)
			ActiveZoeMesh.LoadAsync(FOnSoftObjectLoaded(this, n"OnPlayerVariantLoaded"));
		if (bLoadMioAnimation)
			ActiveMioAnimation.LoadAsync(FOnSoftObjectLoaded(this, n"OnPlayerVariantLoaded"));
		if (bLoadZoeAnimation)
			ActiveZoeAnimation.LoadAsync(FOnSoftObjectLoaded(this, n"OnPlayerVariantLoaded"));
	}

	UFUNCTION()
	private void OnPlayerVariantLoaded(UObject LoadedObject)
	{
		if (ActiveMioMesh.Get() == nullptr)
			return;
		if (ActiveMioAnimation.Get() == nullptr)
			return;
		if (ActiveZoeMesh.Get() == nullptr)
			return;
		if (ActiveZoeAnimation.Get() == nullptr)
			return;

		if (ChapterSelectMesh_Mio != nullptr)
			ChapterSelectMesh_Mio.TransitionToMesh(ActiveMioMesh.Get(), ActiveMioAnimation.Get());
		if (ChapterSelectMesh_Zoe != nullptr)
			ChapterSelectMesh_Zoe.TransitionToMesh(ActiveZoeMesh.Get(), ActiveZoeAnimation.Get());
	}

	UFUNCTION()
	private void OnCameraFadedOut()
	{
		bIsFadingOutCamera = false;
		EMainMenuState CameraState = ActiveState;
		if (CameraState == EMainMenuState::LobbyCharacterSelect)
		{
			// Use the chapter select camera if we're not coming out of the new game cutscene
			if (Lobby::GetLobby() != nullptr && Lobby::GetLobby().StartType != EHazeLobbyStartType::NewGame)
				CameraState = EMainMenuState::LobbyChapterSelect;
		}

		auto& CameraInfo = StateCameras[int(CameraState)];
		if (CameraInfo.Camera != nullptr)
		{
			CameraUser.SnapToCamera(CameraInfo.Camera);
			bHasCamera = true;
		}

		UpdateChapterSelectMeshVisibility();
	}

	UFUNCTION()
	void ShowMainMenu()
	{
		check(ActiveState == EMainMenuState::None);
		OwnerIdentity = nullptr;

		BackgroundWidget = Widget::AddFullscreenWidget(MenuBackgroundWidget, EHazeWidgetLayer::Menu);
		BackgroundWidget.SetRenderOpacity(0.0);
		BackgroundWidget.SetWidgetZOrderInLayer(-100);

		SwitchToState(EMainMenuState::Splash, bSnap = true);
		Widget::SetUseMouseCursor(this, true);
	}

	UFUNCTION()
	bool HasBusyTask()
	{
		if (CVar_MainMenuDebugBusyTask.GetInt() != 0)
			return true;
		FText OutText;
		return Online::HasBusyTask(OutText);
	}

	UFUNCTION(BlueprintPure)
	FText GetBusyTaskText()
	{
		if (CVar_MainMenuDebugBusyTask.GetInt() != 0)
			return FText::FromString("Connecting to EA Servers...");
		FText OutText;
		Online::HasBusyTask(OutText);
		return OutText;
	}

	UFUNCTION(BlueprintPure)
	bool CanCancelBusyTask()
	{
		return Online::CanCancelBusyTask();
	}

	UFUNCTION()
	void CancelBusyTask()
	{
		Online::CancelBusyTask();
	}

	void UpdateMainMenuRichPresence()
	{
		auto Lobby = Lobby::GetLobby();
		if (Lobby != nullptr && Lobby.HasGameStarted())
			return;

		EHazeRichPresence WantedRichPresence = EHazeRichPresence::MainMenu;

		// If we're in an online lobby we should update our rich presence with that
		if (Lobby != nullptr && Lobby.Network != EHazeLobbyNetwork::Local)
			WantedRichPresence = EHazeRichPresence::OnlineLobby;

		// Update presence in main menu if it has changed
		if (WantedRichPresence != AppliedRichPresence)
		{
			Online::UpdateRichPresence(WantedRichPresence);
			AppliedRichPresence = WantedRichPresence;
		}
	}

	void UpdateLevelPreload()
	{
		auto Lobby = Lobby::GetLobby();
		if (Lobby != nullptr
			&& !Lobby.HasGameStarted()
			&& Lobby.LobbyState == EHazeLobbyState::CharacterSelect
			&& Lobby.StartType == EHazeLobbyStartType::NewGame
			&& CVar_PreloadOnMainMenu.GetInt() != 0
			&& !Game::IsEditorBuild())
		{
			if (!bIsPreloading)
			{
				bIsPreloading = true;
				Progress::PreloadProgressPointFromDisk(Progress::GetProgressPointRefID(Lobby.StartProgressPoint));
			}
		}
		else
		{
			if (bIsPreloading)
			{
				bIsPreloading = false;
				Progress::StopActivePreloadsFromDisk();
			}
		}
	}

	UFUNCTION(BlueprintPure)
	bool IsMainMenuOpen()
	{
		return ActiveState != EMainMenuState::None;
	}
};

namespace AMainMenu
{

UFUNCTION(BlueprintPure)
AMainMenu GetMainMenu()
{
	return TListedActors<AMainMenu>().GetSingle();
}

}