namespace Music_Internal
{
	UFUNCTION(BlueprintCallable)
	void MuteEchoesOnStreamerMode(UHazeAudioEmitter Emitter, UHazeAudioMusicSegment MusicSegment)
	{
		if (MusicSegment == nullptr)
			return;

		auto GameSettingsApplicator = Cast<UGameSettingsApplicator>(Game::GetSingleton(UGameSettingsApplicator));
		if (GameSettingsApplicator == nullptr)
			return;
		
		// Don't forget to unmute too...
		if (!GameSettingsApplicator.HasStreamerMode())
		{
			Emitter.SetNodeProperty(MusicSegment, EHazeAudioNodeProperty::MakeUpGain, 0);
		}
		else
		{
			Emitter.SetNodeProperty(MusicSegment, EHazeAudioNodeProperty::MakeUpGain, -96);
		}
	}
}

UCLASS(Abstract)
class UMSD_MainMenu_SoundDef : UHazeMusicSoundDef
{
	EMainMenuState MenuState;
	EMainMenuState PreviouslySelectedState = EMainMenuState::None;

	bool bWaitForSequenceToFinish = false;

	AMainMenu MainMenu;

	UPROPERTY()
	UHazeAudioBusMixer CreditsBusMixer = nullptr;

	UPROPERTY()
	UHazeAudioMusicSegment EchoesMusic = nullptr;

	bool ShouldPlaySplash() const
	{
		return Online::PrimaryIdentity == nullptr;
	}

	UFUNCTION()
	void OnMenuStateChanged(FMainMenuStateChangeData Data)
	{
		auto NewTarget = GetMenuMusicStateFromActiveState(Data.State);

		if (NewTarget != PreviouslySelectedState)
		{
			if (PreviouslySelectedState == EMainMenuState::Credits)
			{
				if (CreditsBusMixer != nullptr)
				{
					Audio::StartOrUpdateUserStateControlledBusMixer(this, CreditsBusMixer, EHazeBusMixerState::FadeOut);
				}
				OnCreditsMusicEnd();
			}

			PreviouslySelectedState = NewTarget;

			switch(NewTarget)
			{
				case EMainMenuState::LobbyCharacterSelect:
				bWaitForSequenceToFinish = true;
				OnSequenceStinger();
				break;
				case EMainMenuState::MainMenu:
				OnMainMenuMusic();
				bWaitForSequenceToFinish = false;
				break;
				case EMainMenuState::Splash:
				if (ShouldPlaySplash())
					OnSplashMusic();
				break;
				case EMainMenuState::Credits:
				{
					if (CreditsBusMixer != nullptr)
					{
						Audio::StartOrUpdateUserStateControlledBusMixer(this, CreditsBusMixer, EHazeBusMixerState::FadeIn);
					}

					Music_Internal::MuteEchoesOnStreamerMode(DefaultEmitter, EchoesMusic);
					OnCreditsMusic();
				}
				break;
				default:
				break;
			}
		}

		MenuState = Data.State;
	}

	EMainMenuState GetMenuMusicStateFromActiveState(EMainMenuState NewState)
	{
		switch(NewState)
		{
			case EMainMenuState::None:
			return EMainMenuState::None;
			case EMainMenuState::LobbyCharacterSelect:
			// Start sequence stinger, and wait for it to complete.
			if (Lobby::GetLobby().StartType == EHazeLobbyStartType::NewGame)
				return EMainMenuState::LobbyCharacterSelect;
			return EMainMenuState::MainMenu;

			case EMainMenuState::Splash:
				return EMainMenuState::Splash;
			case EMainMenuState::Credits:
				return EMainMenuState::Credits;
			case EMainMenuState::MainMenu:
			case EMainMenuState::LobbyChooseStartType:
			case EMainMenuState::LobbyChapterSelect:
			case EMainMenuState::LobbyPlayers:
			case EMainMenuState::LobbyCrossplay:
			case EMainMenuState::LocalWireless:
			case EMainMenuState::Options:
			case EMainMenuState::BusyTask:
				// Start normal main menu music
				return EMainMenuState::MainMenu;
		}
	}

	UFUNCTION(BlueprintEvent)
	void OnMainMenuMusic() {}

	UFUNCTION(BlueprintEvent)
	void OnSplashMusic() {}

	UFUNCTION(BlueprintEvent)
	void OnCreditsMusic() {}

	UFUNCTION(BlueprintEvent)
	void OnCreditsMusicEnd() {}

	UFUNCTION(BlueprintEvent)
	void OnSequenceStinger() {}

	UFUNCTION(BlueprintEvent)
	void OnNewGameCharacterSelect() {}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if (!bWaitForSequenceToFinish)
			return;

		if (MainMenu == nullptr)
		{
			MainMenu = AMainMenu::GetMainMenu();
		}

		if (MainMenu == nullptr)
			return;

		if (MainMenu.CameraUser.GetActiveLevelSequenceActor() == nullptr)
		{
			bWaitForSequenceToFinish = false;
			OnNewGameCharacterSelect();
		}
	}
}