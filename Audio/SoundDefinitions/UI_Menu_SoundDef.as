namespace Menu
{
	AHazeActor GetAudioActor()
	{
		// We just require a persistent actor, doesn't really matter which.
		return Music::GetActor();
	}

	void AttachSoundDef(FSoundDefReference& Ref, FInstigator Instigator)
	{
		if (!Ref.IsValid())
			return;

		auto MenuActor = GetAudioActor();
		if (MenuActor == nullptr)
			return;

		auto SoundDefContext = USoundDefContextComponent::GetOrCreate(MenuActor);
		if (SoundDefContext == nullptr)
			return;

		SoundDefContext.AddSoundDefInstigator(Ref, Instigator);
	}

	void RemoveSoundDef(FSoundDefReference& Ref, FInstigator Instigator)
	{
		if (!Ref.IsValid())
			return;

		auto MenuActor = GetAudioActor();
		if (MenuActor == nullptr)
			return;

		auto SoundDefContext = USoundDefContextComponent::Get(MenuActor);
		if (SoundDefContext == nullptr)
			return;

		SoundDefContext.RemoveSoundDefInstigator(Ref, Instigator);
	}
}

UCLASS(Abstract)
class UUI_Menu_SoundDef : UUI_SoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnTrailUpsell(FTrialUpsellData Data){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY()
	UMainMenuStateWidget ActiveWidget;

	UPROPERTY()
	UPauseMenu PauseMenu;

	UPROPERTY()
	EMainMenuState ActiveState = EMainMenuState::None;

	UPROPERTY()
	UOptionsMenuPage ActiveOptionsPage;
	int ActiveOptionsPageIndex = 0;

	bool bChapterSelectCanMoveLeft = false;
	bool bChapterSelectCanMoveRight = false;

	UFUNCTION(BlueprintPure)
	float GetPauseMenuPanning() const
	{
		if (PauseMenu != nullptr)
		{
			if (PauseMenu.bIsRightPlayer)
			{
				return 1;
			}

			return -1;
		}

		return 0;
	}

	UFUNCTION(BlueprintPure)
	bool ShouldPlaySplash() const
	{
		return Online::PrimaryIdentity == nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
	}

	UFUNCTION()
	void OnMenuStateChanged(FMainMenuStateChangeData Data)
	{
		#if TEST
		if (IsDebugging())
			PrintToScreen(f"{Data.State} - {Data.Widget}", Duration = 10);
		#endif

		auto PreviousState = ActiveState;
		ActiveWidget = Data.Widget;
		ActiveState = Data.State;

		RegisterToMainMenuWidget(Cast<UMainMenuWidget>(ActiveWidget));
		RegisterToOptionsMenuWidget(Cast<UMainMenuOptions>(ActiveWidget));
		RegisterToLevelSelect(Cast<ULobbyChapterSelectWidget>(ActiveWidget));
		RegisterToLobbyChooseStartType(Cast<ULobbyChooseStartTypeWidget>(ActiveWidget));
		RegisterToLobbyPlayersWidget(Cast<ULobbyPlayersWidget>(ActiveWidget));
		RegisterToCharacterSelectWidget(Cast<ULobbyCharacterSelectWidget>(ActiveWidget));

		OnMenuWidgetChanged(Data.Widget, Data.State, PreviousState);
	}

	UFUNCTION(BlueprintEvent)
	void OnMenuWidgetChanged(UMainMenuStateWidget NewWidget, EMainMenuState NewState, EMainMenuState PreviousState)
	{

	}

	UFUNCTION()
	void OnOptionsSwitchToPage(FOptionsMenuSwitchToPageData Data)
	{
		#if TEST
		if (IsDebugging())
			PrintToScreen(f"Options Widget: {Data.Widget.Name}", Duration = 10);
		#endif

		auto PreviousIndex = ActiveOptionsPageIndex;
		ActiveOptionsPageIndex = Data.PageIndex;
		ActiveOptionsPage = Data.Widget;

		RegisterToAllOptions(ActiveOptionsPage);

		OnOptionsSwitched(ActiveOptionsPage, PreviousIndex, Data.PageIndex, Data.FocusCause == EFocusCause::Mouse);
	}

	UFUNCTION(BlueprintEvent)
	void OnOptionsSwitched(UOptionsMenuPage Widget, int PreviousIndex, int NextIndex, bool bByMouse) {}

	// Some events should be used in BP layer, keeping them in AS for debugging.

	UFUNCTION(BlueprintEvent)
	void OnCameraTransition(FMainMenuCameraTransition Data)
	{
		// #if TEST
		// if (IsDebugging())
		// 	PrintToScreen(f"OnCameraTransition: {Data.Type}", Duration = 10);
		// #endif
	}

	UFUNCTION()
	void OnChapterSelectItemsRefresh(FChapterSelectItemsRefreshData Data)
	{
		#if TEST
		if (IsDebugging())
			PrintToScreen(f"OnChapterSelectItemsRefresh - {Data.Widget}", Duration = 10);
		#endif

		RegisterToChapterSelectItems(Data.Widget);

		bChapterSelectCanMoveLeft = Data.Widget.SelectedGroup != 0;
		bChapterSelectCanMoveRight = Data.Widget.SelectedGroup < Data.Widget.SelectionGroups.Num() - 1;

		if (bChapterSelectCanMoveLeft != bChapterSelectCanMoveRight)
			OnChapterSelectStartOrEnd(bChapterSelectCanMoveLeft, bChapterSelectCanMoveRight);
		else
		{
			OnChapterSelectMove();
		}
	}

	UFUNCTION(BlueprintEvent)
	void OnChapterSelectStartOrEnd(bool CanMoveLeft, bool CanMoveRight) {}

	UFUNCTION(BlueprintEvent)
	void OnChapterSelectMove() {}
	
	UFUNCTION()
	void OnChapterSelectPlayerMesh(FChapterSelectPlayerMeshData Data)
	{
		#if TEST
		if (IsDebugging())
			PrintToScreen(f"OnChapterSelectPlayerMesh {Data.Active.Name}, Duration - {Data.Duration}", Duration = 10);
		#endif

		OnChapterSelectPlayerMeshTransition(Data.Active, Data.Duration);
	}

	UFUNCTION(BlueprintEvent)
	void OnChapterSelectPlayerMeshTransition(USkeletalMesh Mesh, float Duration) {}

	UFUNCTION()
	void OnPauseMenuStateChanged(FPauseMenuStateChangeData Data)
	{
		PauseMenu = Data.Widget;
		
		// Register to the different options of the message dialog.
		#if TEST
		if (IsDebugging())
			PrintToScreen(f"OnPauseMenuStateChanged {Data.State}", Duration = 10);
		#endif

		RegisterToPauseMenu(Data.Widget);
		OnPausMenuStateChange(Data.State);
	}

	UFUNCTION(BlueprintEvent)
	void OnPausMenuStateChange(EPauseMenuState State) {}

	UFUNCTION()
	void OnStartGameInitiated() 
	{
		OnStartGame(Lobby::GetLobby().StartType == EHazeLobbyStartType::NewGame);
	}

	UFUNCTION(BlueprintEvent)
	void OnStartGame(bool bNewGame) {}

	UFUNCTION()
	void OnCharacterSelected(FCharacterSelectedData Data) 
	{
		if (Data.bAlreadySelected)
		{
			OnCharacterAlreadySelected(Data.Player);
		}
		else
		{
			if (Data.Player == EHazePlayer::Mio)
				OnCharacterReadyClickedMio(Data.bReady);
			else
				OnCharacterReadyClickedZoe(Data.bReady);
		}
	}

	UFUNCTION(BlueprintEvent)
	void OnCharacterAlreadySelected(EHazePlayer Player) {}

	UFUNCTION()
	void OnBootMenuChanged(FBootMenuStateChangeData Data)
	{
		#if TEST
		if (IsDebugging())
			PrintToScreen(f"Boot - {Data.Widget}", Duration = 10);
		#endif

		RegisterToBootAccessibility(Cast<UInitialBootAccessibilityPage>(Data.Widget));
		RegisterToBootController(Cast<UInitialBootControllerPage>(Data.Widget));
		RegisterToBootEULA(Cast<UInitialBoot_EULA>(Data.Widget));
		RegisterToBootOptions(Cast<UInitialBootOptionsPage>(Data.Widget));
		RegisterToBootPrivacy(Cast<UInitialBoot_PrivacyLicense>(Data.Widget));
		RegisterToBootTelemetry(Cast<UInitialBootTelemetryPage>(Data.Widget));

		OnBootWidgetChanged(Data.Widget);
	}

	UFUNCTION(BlueprintEvent)
	void OnBootWidgetChanged(UInitialBootSequencePage Widget) {}

	void RegisterToBootAccessibility(UInitialBootAccessibilityPage Page)
	{
		if (Page == nullptr)
			return;
		
	}
	
	void RegisterToBootController(UInitialBootControllerPage Page)
	{
		if (Page == nullptr)
			return;
		
		RegisterToPromptOrButton(Page.ContinueButton, true, false);
	}
	
	void RegisterToBootEULA(UInitialBoot_EULA Page)
	{
		if (Page == nullptr)
			return;
		
		RegisterToPromptOrButton(Page.DeclineButton);
		RegisterToPromptOrButton(Page.AcceptButton);
	}

	void RegisterToBootOptions(UInitialBootOptionsPage Page)
	{
		if (Page == nullptr)
			return;
		
		RegisterToPromptOrButton(Page.BackButton, false, true);
		RegisterToPromptOrButton(Page.ContinueButton, true);

		for (auto Option: Page.Options)
		{
			// Early outs if not the type.
			RegisterOptionsButton(Cast<UOptionButtonWidget>(Option));
			RegisterOptionsEnum(Cast<UOptionEnumWidget>(Option));
			RegisterOptionsSlider(Cast<UOptionSliderWidget>(Option));
		}
	}

	void RegisterToBootPrivacy(UInitialBoot_PrivacyLicense Page)
	{
		if (Page == nullptr)
			return;
		
		RegisterToPromptOrButton(Page.AcceptButton);
	}

	void RegisterToBootTelemetry(UInitialBootTelemetryPage Page)
	{
		if (Page == nullptr)
			return;
		
		RegisterToPromptOrButton(Page.DisableButton);
		RegisterToPromptOrButton(Page.EnableButton);
	}
}