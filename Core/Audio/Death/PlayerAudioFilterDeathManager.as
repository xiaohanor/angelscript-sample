struct FPlayerAudioDeathInterpData
{
	float From;
	float To;

	float Current;
	float Timer;
	float Duration;

	FHazeAudioID Rtpc;

	void SetRtpc(const FString& RtpcName)
	{
		Rtpc = FHazeAudioID(RtpcName);
	}

	void Start(const float& InFrom, const float& InTo, const float& NewDuration)
	{
		From = InFrom;
		To = InTo;
		Timer = NewDuration;
		Duration = NewDuration;

		AudioComponent::SetGlobalRTPC(Rtpc, Current);
	}

	void Tick(const float& Delta)
	{
		if (!Interpolating())
			return;

		Timer -= Delta;

		if (Timer < 0)
			Timer = 0;
		
		SetAlpha(1 - (Timer/Duration));
	}

	void SetAlpha(float Alpha)
	{
		float Previous = Current;
		Current = Math::Lerp(From, To, Alpha);

		if (Previous != Current)
		{
			AudioComponent::SetGlobalRTPC(Rtpc, Current);
		}
	}

	bool Interpolating() const
	{
		return Timer > 0;
	}
}

struct FDeathFilterPlayerData
{
	UPlayerDefaultAudioDeathSettings Settings = nullptr;
	bool bActive = false;
	float Alpha = 0;

	float RespawnFadeInDuration = 1;
	float FilteringFadeOutDuration = 1;

	FPlayerAudioDeathInterpData Fade;
	FPlayerAudioDeathInterpData Filter;
}

// Manages the death filtering effect for both players.
class UPlayerAudioFilterDeathManager : UHazeSingleton
{
	private UHazeAudioRuntimeEffectSystem EffectSystem;

	UPROPERTY()
	UHazeAudioEffectShareSet Music_BitCrusher;

	UPROPERTY()
	UHazeAudioEffectShareSet Vo_BitCrusher;
	
	UPROPERTY()
	UHazeAudioEffectShareSet SfxEffect;

	UPROPERTY()
	UHazeAudioEffectShareSet VoFiltering;

	UPROPERTY()
	UHazeAudioEffectShareSet GameOverMusic_Stutter;

	UPROPERTY()
	UHazeAudioEffectShareSet GameOverMusic_Dist;

	UPROPERTY()
	UHazeAudioEffectShareSet GameOverMusic_PitchShift;

	UPROPERTY()
	UHazeAudioEvent GameOverStartEvent;

	UPROPERTY()
	UHazeAudioEvent GameOverStopEvent;

	UPROPERTY(EditDefaultsOnly)
	UHazeAudioBusMixer GameOverBusMixer;

	const FHazeAudioID Rtpc_RuntimeEffect_PlayerDeath_StutterLength = FHazeAudioID("Rtpc_RuntimeEffect_PlayerDeath_StutterLength");

	const FHazeAudioID Rtpc_DryWet_Mix = FHazeAudioID("Rtpc_RuntimeEffect_PlayerDeath_DryWet_Mix");
	const FHazeAudioID Rtpc_Left_Mix = FHazeAudioID("Rtpc_RuntimeEffect_PlayerDeath_Left_Mix");
	const FHazeAudioID Rtpc_Right_Mix = FHazeAudioID("Rtpc_RuntimeEffect_PlayerDeath_Right_Mix");

	const FHazeAudioID Rtpc_DryWet_Stutter_Mix = FHazeAudioID("Rtpc_RuntimeEffect_PlayerDeath_Stutter_Mix");

	const FHazeAudioID Rtpc_RuntimeEffect_GameOver_DryWet_Mix = FHazeAudioID("Rtpc_RuntimeEffect_GameOver_DryWet_Mix");
	const FHazeAudioID Rtpc_RuntimeEffect_GameOver_StutterLength = FHazeAudioID("Rtpc_RuntimeEffect_GameOver_StutterLength");

	UHazeAudioMusicManager MusicManager;

	FHazeAudioRuntimeEffectInstance FilteringInstance;
	FHazeAudioRuntimeEffectInstance VoBitCrusherInstance;
	FHazeAudioRuntimeEffectInstance MusicBitCrusherInstance;
	FHazeAudioRuntimeEffectInstance StutterInstance;
	FHazeAudioRuntimeEffectInstance FilteringVOInstance;

	FHazeAudioRuntimeEffectInstance GameOverStutterInstance;
	FHazeAudioRuntimeEffectInstance GameOverDistInstance;
	FHazeAudioRuntimeEffectInstance GameOverPitchInstance;

	FHazeAudioPostEventInstance GameOverStartInstance;

	UHazeAudioBusMixer UsedMixerGameOver = nullptr;

	private int ActivePlayers = 0;

	private TArray<FDeathFilterPlayerData> PlayerDatas;
	default PlayerDatas.SetNum(2);
	float CurrentAlpha = -1;

	bool bStutterReachedTarget = false;

	FPlayerAudioDeathInterpData StutterMix;
	FPlayerAudioDeathInterpData GameOverStutterMix;
	FPlayerAudioDeathInterpData GameOverStutterPitchShift;

	// includes loading etc.
	float GameOverDuration = 0;
	bool bWasGameOver = false;
	bool bHasActiveEffects = false;

	TArray<float> GameOverStutterModifiersInOrder;
	default GameOverStutterModifiersInOrder.Add(1);
	default GameOverStutterModifiersInOrder.Add(.5);
	default GameOverStutterModifiersInOrder.Add(0.25);
	default GameOverStutterModifiersInOrder.Add(0.125);

	int MusicBeatStep = 0;
	int MusicBeatCount = 0;

	UFUNCTION(BlueprintOverride)
	void Initialize()
	{
		EffectSystem = Game::GetSingleton(UHazeAudioRuntimeEffectSystem);

		StutterMix.SetRtpc("Rtpc_RuntimeEffect_PlayerDeath_Stutter_Mix");
		GameOverStutterMix.SetRtpc("Rtpc_RuntimeEffect_GameOver_Stutter_Mix");
		GameOverStutterPitchShift.SetRtpc("Rtpc_RuntimeEffect_GameOver_DryWet_Mix");

		SetupPlayerData(PlayerDatas[0], true);
		SetupPlayerData(PlayerDatas[1], false);

		MusicManager = UHazeAudioMusicManager::Get();
	}

	void SetupPlayerData(FDeathFilterPlayerData& Data, bool bIsMio)
	{
		Data.Fade.SetRtpc(bIsMio ? "Rtpc_Player_Death_Mio_Fade" : "Rtpc_Player_Death_Zoe_Fade");
		Data.Filter.SetRtpc(bIsMio ? "Rtpc_HazeFiltering_Mio" : "Rtpc_HazeFiltering_Zoe");
	}

	UFUNCTION(BlueprintOverride)
	void Shutdown()
	{
		ReleaseAllEffects();
	}
	
	UFUNCTION(BlueprintOverride)
	void ResetStateBetweenLevels()
	{
		if(bWasGameOver)
			return;

		StopFilteringForPlayer(EHazePlayer::Mio);
		StopFilteringForPlayer(EHazePlayer::Zoe);
	}

	void ReleaseAllEffects()
	{
		ReleaseEffect(FilteringInstance);
		ReleaseEffect(FilteringVOInstance);
		ReleaseEffect(VoBitCrusherInstance);
		ReleaseEffect(MusicBitCrusherInstance);
		ReleaseEffect(StutterInstance);
		ReleaseEffect(GameOverStutterInstance);
		ReleaseEffect(GameOverDistInstance);
		ReleaseEffect(GameOverPitchInstance);
	}

	void SetRandomBitCrusherValues()
	{
	}

	void SetRandomStutterValues()
	{
		AudioComponent::SetGlobalRTPC(Rtpc_RuntimeEffect_PlayerDeath_StutterLength, Math::RandRange(0., 1.));
	}

	void StartStutter(UHazeAudioEffectShareSet ShareSet, UPlayerDefaultAudioDeathSettings Settings)
	{
		if (ShareSet == nullptr)
			return;

		if (bWasGameOver)
			return;

		SetRandomStutterValues();
		bStutterReachedTarget = false;
		StutterInstance = (EffectSystem.StartControlled(this, ShareSet));
		StutterInstance.SetAlpha(1);

		StutterMix.Start(0, 1, Settings.StutterDurationFadeIn);
	}

	void StartMusicBitCrusher(UHazeAudioEffectShareSet ShareSet)
	{
		if (ShareSet == nullptr)
			return;

		if (bWasGameOver)
			return;

		SetRandomBitCrusherValues();
		MusicBitCrusherInstance = (EffectSystem.StartControlled(this, ShareSet));
	}

	void StartVOBitCrusher(UHazeAudioEffectShareSet ShareSet)
	{
		if (ShareSet == nullptr)
			return;

		VoBitCrusherInstance = (EffectSystem.StartControlled(this, ShareSet));
	}

	void StartVOFilter(UHazeAudioEffectShareSet ShareSet)
	{
		if (ShareSet != nullptr && !FilteringVOInstance.IsValid())
			FilteringVOInstance = (EffectSystem.StartControlled(this, ShareSet));
	}

	void PlayerFilterActivated(
		AHazePlayerCharacter Player,
		UPlayerDefaultAudioDeathSettings Settings,
		bool bGameOver,
		bool bStartVOBitCrusher)
	{
		auto PlayerIndex = int(Player.Player);
		PlayerDatas[PlayerIndex].bActive = true;
		PlayerDatas[PlayerIndex].Settings = Settings;

		if (bGameOver && !bWasGameOver)
		{
			GameOverDuration = 0;
			bWasGameOver = true;
			
			if (!Settings.bDisableEffectsAndGameOverEvents)
			{
				GameOverStartInstance = AudioComponent::PostGlobalEvent(GameOverStartEvent);

				// Cmon music manager gives us your beat!
				MusicManager.OnMusicBeat.AddUFunction(this, n"OnGameOverMusicBeat");
			}

			UsedMixerGameOver = GameOverBusMixer;
			if (Settings.GameOverBusMixerOverride != nullptr) 
			{
				UsedMixerGameOver = Settings.GameOverBusMixerOverride;
			} 

			if(UsedMixerGameOver != nullptr)
				Audio::StartOrUpdateUserStateControlledBusMixer(this, UsedMixerGameOver, EHazeBusMixerState::FadeIn);
		}

		if (!bHasActiveEffects && !Settings.bDisableEffectsAndGameOverEvents)
		{
			bHasActiveEffects = true;

			if (SfxEffect != nullptr)
				FilteringInstance = (EffectSystem.StartControlled(this, SfxEffect));

			StartMusicBitCrusher(Music_BitCrusher);
			if (bStartVOBitCrusher)
				StartVOBitCrusher(Vo_BitCrusher);
			//StartStutter(MusicAndVoEffect_Stutter, Settings);
			// StartVOFilter(VoFiltering);
		}
		else if (!StutterInstance.IsValid())
		{
			// Restart it!
			//StartStutter(MusicAndVoEffect_Stutter, Settings);
		}
	}

	float GetNextModifier(int Step)
	{
		if (!GameOverStutterModifiersInOrder.IsValidIndex(Step))
			return 0.125;

		return GameOverStutterModifiersInOrder[Step];
	}

	UFUNCTION()
	private void OnGameOverMusicBeat()
	{
		float BeatBaseDuration = (60. / MusicManager.BeatsPerMinute);
		
		if (!GameOverStutterInstance.IsValid())
		{
			MusicBeatCount = 0;
			MusicBeatStep = 0;
			float BeatDuration = BeatBaseDuration * GetNextModifier(MusicBeatStep);

			GameOverStutterMix.Start(0, 1, BeatDuration);
			// GameOverStutterPitchShift.Start(0, 1, BeatBaseDuration * 8);
			AudioComponent::SetGlobalRTPC(Rtpc_RuntimeEffect_GameOver_DryWet_Mix, 1, int(BeatBaseDuration * 6 * 1000));

			#if EDITOR
			Log(f"BeatDuration:{BeatDuration} - {MusicManager.BeatsPerMinute}");
			#endif
			AudioComponent::SetGlobalRTPC(Rtpc_RuntimeEffect_GameOver_StutterLength, BeatDuration);

			if (GameOverMusic_Stutter != nullptr)
				GameOverStutterInstance = (EffectSystem.StartControlled(this, GameOverMusic_Stutter));

			if (GameOverMusic_PitchShift != nullptr)
				GameOverPitchInstance = (EffectSystem.StartControlled(this, GameOverMusic_PitchShift));

			if (GameOverMusic_Dist != nullptr)
				GameOverDistInstance = (EffectSystem.StartControlled(this, GameOverMusic_Dist));
		}
		else
		{
			++MusicBeatCount;
			if (MusicBeatCount % 2 != 0) 
				return;

			++MusicBeatStep;

			float BeatDuration = BeatBaseDuration * GetNextModifier(MusicBeatStep);
			#if EDITOR
			Log(f"BeatDuration:{BeatDuration} - {MusicManager.BeatsPerMinute}");
			#endif
			AudioComponent::SetGlobalRTPC(Rtpc_RuntimeEffect_GameOver_StutterLength, BeatDuration);
		}
	}


	void ReleaseEffect(FHazeAudioRuntimeEffectInstance& EffectInstance)
	{
		if (!EffectInstance.IsValid())
			return;

		EffectInstance.Release();
	}

	UPlayerDefaultAudioDeathSettings GetActivePlayerSettings()
	{
		for (auto& Data : PlayerDatas)
		{
			if (!Data.bActive)
				continue;
			
			return Data.Settings;
		}

		return nullptr;
	}

	void StartFilteringForPlayer(EHazePlayer Player, 
		float RespawnFadeOutDuration, float FilteringFadeInDuration,
		float RespawnFadeInDuration, float FilteringFadeOutDuration)
	{
		auto& PlayerData = PlayerDatas[int(Player)];

		// Make sure the respawn times isn't zero or to low.
		PlayerData.Fade.Start(0, 1, Math::Max(0.5, RespawnFadeOutDuration));
		PlayerData.Filter.Start(1, 0, FilteringFadeInDuration);

		PlayerData.RespawnFadeInDuration = Math::Max(0.25, RespawnFadeInDuration);
		PlayerData.FilteringFadeOutDuration = FilteringFadeOutDuration;
	}

	void StopFilteringForPlayer(EHazePlayer Player)
	{
		auto& PlayerData = PlayerDatas[int(Player)];
		PlayerData.bActive = false;

		// No point in doing anything.
		if (bHasActiveEffects)
		{
			if (PlayerData.Fade.Interpolating())
			{
				// Already fading out, ignore it.
				if (PlayerData.Fade.To == 0)
					return;
				
				// Fade them out based on the current time it has already faded in.
				auto FadeDuration = Math::Max(0.1, PlayerData.Fade.Duration - PlayerData.Fade.Timer);
				PlayerData.Fade.Start(1, 0, FadeDuration);
				PlayerData.Filter.Start(0, 1, Math::Max(0.1, PlayerData.Filter.Duration - PlayerData.Filter.Timer));
				GameOverStutterMix.Start(1, 0, Math::Max(0.1, GameOverStutterMix.Duration - GameOverStutterMix.Timer));
				// GameOverStutterPitchShift.Start(1, 0, PlayerData.RespawnFadeInDuration);
				AudioComponent::SetGlobalRTPC(Rtpc_RuntimeEffect_GameOver_DryWet_Mix, 0, int(FadeDuration* 1000));
				return;
			}
		}

		PlayerData.Fade.Start(1, 0, PlayerData.RespawnFadeInDuration);
		PlayerData.Filter.Start(0, 1, PlayerData.FilteringFadeOutDuration);
		GameOverStutterMix.Start(1, 0, PlayerData.RespawnFadeInDuration);

		// Force reset.
		if (!bHasActiveEffects)
		{
			PlayerData.Fade.SetAlpha(1);
			PlayerData.Filter.SetAlpha(1);
			GameOverStutterMix.SetAlpha(1);
		}

		// GameOverStutterPitchShift.Start(1, 0, PlayerData.RespawnFadeInDuration);
		AudioComponent::SetGlobalRTPC(Rtpc_RuntimeEffect_GameOver_DryWet_Mix, 0, int(PlayerData.RespawnFadeInDuration * 1000));
	}

	bool ArePlayersGameOver()
	{
		auto Mio = Game::Mio;
		if (Mio == nullptr)
			return true;

		auto HealthComp = UPlayerHealthComponent::Get(Game::Mio);

		if (Mio.bIsControlledByCutscene)
			return false;

		if(HealthComp.bIsGameOver)
		{
			return true;
		}
		else
		{
			auto OtherPlayerHealthComp = UPlayerHealthComponent::Get(Game::Zoe);
			return HealthComp.bIsDead && OtherPlayerHealthComp.bIsDead; 
		}	
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bHasActiveEffects && !bWasGameOver)
			return;
		
		if (Game::IsPausedByPlayer())
			return;

		// If we don't have to tick, don't.
		bool bShouldTick = false;

		auto UndilatedDeltaTime = Time::UndilatedWorldDeltaSeconds;

		if (bWasGameOver)
		{
			bool bRespawned = false;
			// Has we resumed gameplay yet? i.e respawned.
			if (!Game::IsInLoadingScreen() && !ArePlayersGameOver())
			{
				bRespawned = true;
			}

			GameOverDuration += UndilatedDeltaTime;
			// PrintToScreenScaled("" + GameOverDuration);

			// Fade them all out! Load is taking to long for some reason.
			if (bRespawned || GameOverDuration > 10)
			{
				MusicManager.OnMusicBeat.UnbindObject(this);
				bWasGameOver = false;
				if (bRespawned)
				{
					GameOverStartInstance.Stop(500);
					AudioComponent::PostGlobalEvent(GameOverStopEvent);
				}

				StopFilteringForPlayer(EHazePlayer::Mio);
				StopFilteringForPlayer(EHazePlayer::Zoe);
				GameOverDuration = 0;

				if(UsedMixerGameOver != nullptr)
				{
					Audio::StartOrUpdateUserStateControlledBusMixer(this, UsedMixerGameOver, EHazeBusMixerState::FadeOut);
					UsedMixerGameOver = nullptr;
				}
			}

			// Continue to tick if gameover is triggered
			bShouldTick = bWasGameOver;
		}

		float MaxValue = 0;
		float MaxFilteringValue = 0;
		for (auto& PlayerData : PlayerDatas)
		{

			PlayerData.Fade.Tick(UndilatedDeltaTime);
			PlayerData.Filter.Tick(UndilatedDeltaTime);

			PlayerData.Alpha = PlayerData.Fade.Current;
			MaxValue = Math::Max(PlayerData.Alpha, MaxValue);

			MaxFilteringValue = Math::Max(1 - PlayerData.Filter.Current, MaxFilteringValue);

			if (PlayerData.bActive || PlayerData.Alpha > 0 || PlayerData.Filter.Interpolating())
				bShouldTick = true;
		}

		// These decide if the effects should be heard and how much. Add to settings?
		AudioComponent::SetGlobalRTPC(Rtpc_Left_Mix, PlayerDatas[0].Alpha);
		AudioComponent::SetGlobalRTPC(Rtpc_Right_Mix, PlayerDatas[1].Alpha);
		AudioComponent::SetGlobalRTPC(Rtpc_DryWet_Mix, MaxValue);
		// AudioComponent::SetGlobalRTPC(Rtpc_RuntimeEffect_GameOver_DryWet_Mix, MaxValue);

		if (StutterInstance.IsValid())
		{
			StutterMix.Tick(UndilatedDeltaTime);

			if (bStutterReachedTarget && StutterMix.Current <= 0)
			{
				StutterInstance.SetAlpha(0);
				StutterInstance.Release();
			}
			else if (!bStutterReachedTarget && StutterMix.Current >= 1)
			{
				auto Settings = GetActivePlayerSettings();
				float FadeOutDuration = 1;
				if (Settings != nullptr)
				{
					FadeOutDuration = Settings.StutterDurationFadeOut;
				}

				bStutterReachedTarget = true;
				StutterMix.Start(1, 0, FadeOutDuration);
			}
		}

		if (GameOverStutterInstance.IsValid())
			GameOverStutterMix.Tick(UndilatedDeltaTime);
		SetEffectAlpha(GameOverStutterInstance, MaxValue);
		SetEffectAlpha(MusicBitCrusherInstance, MaxValue);
		SetEffectAlpha(VoBitCrusherInstance, MaxFilteringValue);

		if (!bShouldTick)
		{
			bHasActiveEffects = false;
			ReleaseAllEffects();
		}
	}

	void SetEffectAlpha(FHazeAudioRuntimeEffectInstance& EffectInstance, float Alpha)
	{
		if (!EffectInstance.IsValid())
			return;
		
		EffectInstance.SetAlpha(Alpha);
	}
}