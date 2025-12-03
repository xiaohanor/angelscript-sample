const FConsoleVariable CVar_VoxDisableMissingLocAssets("HazeVox.DisableMissingLocAssets", 1);
const FConsoleVariable CVar_VoxDisableMissingLocAssetsInEditor("HazeVox.DisableMissingLocAssetsInEditor", 0);

event void FVoxToggleTriggerEnabledEvent(FInstigator Instigator);

struct FHazeVoxControllerPlayParams
{
	UHazeVoxAsset VoxAsset;
	TArray<AHazeActor> Actors;
	EHazeVoxLaneInterruptType LaneInterruptType;
	bool bInterruptBothPlayers;
}

enum EVoxControllerCanTriggerResult
{
	CanTrigger,
	BlockedButCanQueue,
	FullyBlocked
}

struct FHazeVoxPausedActor
{
	AHazeActor Actor;
	TArray<FInstigator> Instigators;
}

struct FHazeVoxPlayingStoppedDelegateTrigger
{
	FOnHazeVoxAssetPlayingStopped PlayingStoppedDelegate;
	bool bInterrupted;
}

#if TEST
struct FHazeVoxDebugPlayOnTickItem
{
	TMap<FName, int32> VoxAssetPlayed;
}
#endif

class UHazeVoxController : UHazeVoxControllerBaseSingleton
{
	private bool bManagerActive = true;

	private TMap<FName, UVoxSharedRuntimeAsset> SharedRuntimeAssets;
	private TArray<FHazeVoxPausedActor> PausedActors;

	private TArray<FName> PersistentPlayedOnceVoxAssets;

	private bool bSeedSaltSet = false;
	private int RandSeedSalt = 0;

	private TArray<FHazeVoxPlayingStoppedDelegateTrigger> PlayingStoppedDelegates;

	private FVoxToggleTriggerEnabledEvent OnPlayerTriggersEnabled;
	private FVoxToggleTriggerEnabledEvent OnPlayerTriggersDisabled;

	private bool bExternalPause = false;

#if TEST
	private bool bDebugPlayOnTickEnabled = false;
	private TArray<FHazeVoxDebugPlayOnTickItem> DebugPlayOnTicks;
	private TArray<FName> DebugPlayOnTickIgnored;
	private const int DebugPlayOnTickNumFrames = 10;
#endif

	UFUNCTION(BlueprintOverride)
	void Initialize()
	{
#if TEST
		bDebugPlayOnTickEnabled = VoxDebug::IsVoDesigner();
		DebugPlayOnTicks.Reset();
		DebugPlayOnTicks.Add(FHazeVoxDebugPlayOnTickItem());
#endif
	}

	UFUNCTION(BlueprintOverride)
	void Shutdown()
	{
	}

	UFUNCTION(BlueprintOverride)
	void ResetStateBetweenLevels()
	{
		auto VoxRunner = UHazeVoxRunner::Get();
		VoxRunner.Reset();

		PausedActors.Reset();

		OnPlayerTriggersEnabled.Clear();
		OnPlayerTriggersDisabled.Clear();

		// Save persistent data
		for (TMapIterator<FName, UVoxSharedRuntimeAsset>& SharedAssetIt : SharedRuntimeAssets)
		{
			UVoxSharedRuntimeAsset SharedAsset = SharedAssetIt.GetValue();
			if (SharedAsset.VoxAsset.bPersistentPlayOnce)
			{
				const bool bPlayOnce = SharedAsset.VoxAsset.PlayOnce && SharedAsset.bPlayedOnce;
				const bool bPlayAllOnce = SharedAsset.VoxAsset.PlayAllOnce && SharedAsset.bAllPlayedOnce;
				if (bPlayOnce || bPlayAllOnce)
				{
					PersistentPlayedOnceVoxAssets.AddUnique(SharedAssetIt.Key);
				}
			}
		}

		SharedRuntimeAssets.Reset();

		// Set SeedSalt here so we get a new one on game over
		if (Network::HasWorldControl())
		{
			int NewRandSeedSalt = Math::Rand();
			NetSetRandSeedSalt(NewRandSeedSalt);
		}

#if TEST
		DebugPlayOnTicks.Reset();
		DebugPlayOnTicks.Add(FHazeVoxDebugPlayOnTickItem());
		DebugPlayOnTickIgnored.Reset();
#endif
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
#if TEST
		if (bDebugPlayOnTickEnabled)
		{
			OnTickDebugUpdate();
		}
#endif
		if (bSeedSaltSet)
		{
			const UHazeLobby Lobby = Lobby::GetLobby();
			if (Lobby == nullptr || !Lobby.HasGameStarted())
			{
				// Disconnected
				bSeedSaltSet = false;

				// Reset Persistent data when we leave game
				PersistentPlayedOnceVoxAssets.Reset();
			}
		}
		else if (Network::HasWorldControl())
		{
			const UHazeLobby Lobby = Lobby::GetLobby();
			if (Lobby != nullptr && Lobby.HasGameStarted())
			{
				int NewRandSeedSalt = Math::Rand();
				NetSetRandSeedSalt(NewRandSeedSalt);
			}
		}

		// TODO: Reset everything if not in game?
		if (!VoxHelpers::InGame())
			return;

		// Check if game is paused
		const bool bGamePaused = Game::IsPausedForAnyReason();
		if (bExternalPause != bGamePaused)
		{
			ToggleExternalPause(bGamePaused);
		}

		// Early out if paused
		if (bExternalPause)
			return;

		// Remove paused actor that has become invalid
		for (int i = PausedActors.Num() - 1; i >= 0; --i)
		{
			if (!IsValid(PausedActors[i].Actor) || PausedActors[i].Actor.IsActorBeingDestroyed())
			{
				PausedActors.RemoveAtSwap(i);
			}
		}

		// Unpause players paused by this controller if they are no longer dead
		for (int i = PausedActors.Num() - 1; i >= 0; --i)
		{
			const int ThisIndex = PausedActors[i].Instigators.FindIndex(this);
			if (ThisIndex >= 0)
			{
				const UPlayerHealthComponent PlayerHealthComp = UPlayerHealthComponent::Get(PausedActors[i].Actor);
				if (PlayerHealthComp != nullptr)
				{
					const bool bPlayerDead = PlayerHealthComp.bIsDead;
					if (!bPlayerDead)
					{
						PausedActors[i].Instigators.RemoveAtSwap(ThisIndex);
						if (PausedActors[i].Instigators.IsEmpty())
						{
							PausedActors.RemoveAtSwap(i);
						}
					}
				}
			}
		}

		// Trigger any saved delegates
		if (PlayingStoppedDelegates.Num() > 0)
		{
			// Make copy of array in case new delegates are added by delegates being excecuted
			TArray<FHazeVoxPlayingStoppedDelegateTrigger> PlayingStoppedDelegatesCopy = PlayingStoppedDelegates;
			PlayingStoppedDelegates.Reset();

			for (FHazeVoxPlayingStoppedDelegateTrigger& PlayingStopped : PlayingStoppedDelegatesCopy)
			{
				PlayingStopped.PlayingStoppedDelegate.ExecuteIfBound(PlayingStopped.bInterrupted);
			}
		}

		for (TMapIterator<FName, UVoxSharedRuntimeAsset>& SharedAssetIt : SharedRuntimeAssets)
		{
			UVoxSharedRuntimeAsset SharedAsset = SharedAssetIt.GetValue();
			if (SharedAsset.bTickCooldown)
			{
				SharedAsset.TickCooldown(DeltaTime);
			}
		}

#if TEST
		DebugTemporalLog();
#endif
	}

	bool IsManagerActive() const
	{
		return bManagerActive;
	}

	void CheckActorDeath(AHazeActor Actor)
	{
		// Only do this for players with health component
		// Also add for NPCs if need in the future (should only matter if enemy lines need to be queued on play)
		UPlayerHealthComponent PlayerHealthComp = UPlayerHealthComponent::Get(Actor);
		if (PlayerHealthComp != nullptr)
		{
			const bool bPlayerPaused = IsActorPaused(Actor);
			const bool bPlayerDead = PlayerHealthComp.bIsDead;
			if (bPlayerDead && !bPlayerPaused)
			{
				PauseActor(Actor, this);
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbInternalPlay(FHazeVoxControllerPlayParams PlayParams)
	{
		VoxDebug::TelemetryVoxAsset(n"vox_play", PlayParams.VoxAsset, "crumbed", true);
		InternalPlayLocal(PlayParams, FOnHazeVoxAssetPlayingStopped());
	}

	void InternalPlayLocal(FHazeVoxControllerPlayParams PlayParams, FOnHazeVoxAssetPlayingStopped PlayingStoppedDelegate)
	{
		UHazeVoxAsset VoxAsset = PlayParams.VoxAsset;
		if (!bManagerActive)
		{
			const FString ErrorMessage = f"HazeVoxController Play called while inactive, VoxAsset: {VoxAsset}";
			TEMPORAL_LOG("Vox/Summary").Event(ErrorMessage);
			PrintError(ErrorMessage);

			TriggerPlayingStoppedDelegate(PlayingStoppedDelegate, true);
			return;
		}

		if (!IsValid(VoxAsset))
		{
			const FString ErrorMessage = f"HazeVoxController Play called with invalid VoxAsset: {VoxAsset}";
			TEMPORAL_LOG("Vox/Summary").Event(ErrorMessage);
			PrintError(ErrorMessage);

			TriggerPlayingStoppedDelegate(PlayingStoppedDelegate, true);
			return;
		}

#if EDITOR
		bool bFilterOnLoc = CVar_VoxDisableMissingLocAssetsInEditor.GetInt() != 0;
#else
		bool bFilterOnLoc = CVar_VoxDisableMissingLocAssets.GetInt() != 0;
#endif

		if (bFilterOnLoc && Game::GetHazeGameInstance().VoxLocBnk != nullptr)
		{
			FVoxSupportedLocBnk VoxSupportedLocBnk;
			if (Game::GetHazeGameInstance().VoxLocBnk.VoxAssetToLocBnc.Find(VoxAsset.Name, VoxSupportedLocBnk))
			{
#if EDITOR
				FName Loc = Editor::GetGameLocalizationPreviewLanguage();
#else
				FName Loc = FName(Internationalization::GetCurrentLanguage());
#endif
				if (VoxSupportedLocBnk.UnsupportedLocs.Contains(Loc))
				{
					const FString ErrorMessage = f"Vox Asset not supported in current loc: {Loc} {VoxAsset}";
					TEMPORAL_LOG("Vox/Summary").Event(ErrorMessage);
					return;
				}
			}
		}

		// Validate voice lines
		if (VoxAsset.VoiceLines.Num() <= 0)
		{
			const FString ErrorMessage = f"HazeVoxController Play called with empty VoxAsset: {VoxAsset}";
			TEMPORAL_LOG("Vox/Summary").Event(ErrorMessage);
			PrintError(ErrorMessage);

			TriggerPlayingStoppedDelegate(PlayingStoppedDelegate, true);
			return;
		}

		for (int i = 0; i < VoxAsset.VoiceLines.Num(); ++i)
		{
			if (VoxAsset.VoiceLines[i].AudioEvent == nullptr)
			{
				const FString ErrorMessage = f"HazeVoxController Play called with missing audio event on VL: {i}, VoxAsset: {VoxAsset}";
				TEMPORAL_LOG("Vox/Summary").Event(ErrorMessage);
				PrintError(ErrorMessage);

				TriggerPlayingStoppedDelegate(PlayingStoppedDelegate, true);
				return;
			}
		}

		UVoxSharedRuntimeAsset SharedAsset = FindOrAddSharedRuntimeAsset(VoxAsset);
		TArray<AHazeActor> MatchingActors;
		EVoxControllerCanTriggerResult CanTriggerResult = MatchActorsAndCheckCanTrigger(SharedAsset, PlayParams.Actors, PlayParams.LaneInterruptType, MatchingActors);

		if (CanTriggerResult == EVoxControllerCanTriggerResult::FullyBlocked)
		{
			VoxDebug::TelemetryVoxAsset(n"vox_not_starting", VoxAsset, "blocked");
			TriggerPlayingStoppedDelegate(PlayingStoppedDelegate, true);
			return;
		}

		UHazeVoxRunner VoxRunner = UHazeVoxRunner::Get();
		UVoxLane Lane = VoxRunner.FindLane(SharedAsset.VoxAsset.Lane);

		bool bTryQueue = CanTriggerResult == EVoxControllerCanTriggerResult::BlockedButCanQueue;

		if (CanTriggerResult == EVoxControllerCanTriggerResult::CanTrigger)
		{
			bool bPlay = Lane.TestPriority(SharedAsset, MatchingActors);
			if (bPlay)
			{
				int VoiceLineIndex = SharedAsset.GetNextIndex();
				UVoxRuntimeAsset RuntimeAsset = UVoxRuntimeAsset();
				RuntimeAsset.Init(SharedAsset, MatchingActors, PlayingStoppedDelegate);

				if (PlayParams.LaneInterruptType != EHazeVoxLaneInterruptType::None)
				{
					RuntimeAsset.SetLaneInterrupt(PlayParams.LaneInterruptType, PlayParams.bInterruptBothPlayers);
				}

				UHazeVoxRunner::Get().PlayLocal(RuntimeAsset, VoiceLineIndex, false);

				return;
			}
			else
			{
#if TEST
				VoxDebug::TemporalLogEvent(SharedAsset.TemporalLogPath, f"{SharedAsset.VoxAsset.Name} can't trigger due to priority");
#endif
				bTryQueue = true;
			}
		}

		if (bTryQueue && SharedAsset.VoxAsset.bQueueOnPlay && SharedAsset.VoxAsset.Type != EHazeVoxAssetType::Effort)
		{
			bool bCanQueueOnLane = Lane.CanAssetQueue(SharedAsset);
			if (bCanQueueOnLane)
			{
				FVoxLaneQueueItem QueueItem;
				QueueItem.RuntimeAsset = UVoxRuntimeAsset();
				QueueItem.RuntimeAsset.Init(SharedAsset, MatchingActors, PlayingStoppedDelegate);

				Lane.QueueAsset(QueueItem);
#if TEST
				VoxDebug::TemporalLogEvent(SharedAsset.TemporalLogPath, f"{SharedAsset.VoxAsset.Name} placed on queue");
				VoxDebug::TelemetryVoxAsset(n"vox_not_starting", VoxAsset, "queued");
#endif
			}
			else
			{
				TriggerPlayingStoppedDelegate(PlayingStoppedDelegate, true);
#if TEST
				VoxDebug::TemporalLogEvent(SharedAsset.TemporalLogPath, f"{SharedAsset.VoxAsset.Name} can't be queued on lane");
				VoxDebug::TelemetryVoxAsset(n"vox_not_starting", VoxAsset, "cant_queue");
#endif
			}
		}
		else
		{
			TriggerPlayingStoppedDelegate(PlayingStoppedDelegate, true);
#if TEST
			VoxDebug::TelemetryVoxAsset(n"vox_not_starting", VoxAsset, "no_queue");
			VoxDebug::TemporalLogEvent(SharedAsset.TemporalLogPath, f"{SharedAsset.VoxAsset.Name} not queued");
#endif
		}
	}

	UFUNCTION(BlueprintOverride)
	void Play(UHazeVoxAsset VoxAsset, TArray<AHazeActor> Actors, FOnHazeVoxAssetPlayingStopped PlayingStoppedDelegate, UObject CallingVOSoundDef, EHazeVoxLaneInterruptType LaneInterruptType, bool bInterruptBothPlayers)
	{
#if TEST
		if (bDebugPlayOnTickEnabled && IsValid(VoxAsset))
		{
			OnTickDebugPlay(VoxAsset.Name);
		}
#endif

		FHazeVoxControllerPlayParams PlayParams;
		PlayParams.VoxAsset = VoxAsset;
		PlayParams.Actors = Actors;
		PlayParams.LaneInterruptType = LaneInterruptType;
		PlayParams.bInterruptBothPlayers = bInterruptBothPlayers;

		// Play crumbed if we are on CallingVOSoundDef control side
		if (IsValid(VoxAsset) && IsValid(CallingVOSoundDef))
		{
			if (CallingVOSoundDef.HasControl())
			{
				// devEnsure here so we know what VoxAsset we are trying to play. Otherwise we would get less info from the network system error
				for (auto Actor : PlayParams.Actors)
				{
					if (!devEnsure(IsValid(Actor), f"Attempted to play vox asset {VoxAsset} with an invalid actor"))
						return;

					if (!devEnsure(Actor.IsObjectNetworked(), f"Attempted to play vox asset {VoxAsset} crumbed using non networked Actor {Actor}"))
						return;
				}

				const FString Message = f"Playing crumbed vox asset {VoxAsset} from {CallingVOSoundDef}";
				TEMPORAL_LOG("Vox/Summary").Event(Message);

				CrumbInternalPlay(PlayParams);
			}
			return;
		}

		VoxDebug::TelemetryVoxAsset(n"vox_play", VoxAsset, "local");
		InternalPlayLocal(PlayParams, PlayingStoppedDelegate);
	}

	UFUNCTION(BlueprintOverride)
	void StopVox()
	{
		if (bManagerActive)
		{
			bManagerActive = false;
			UHazeVoxRunner::Get().Reset();

			OnPlayerTriggersDisabled.Broadcast(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void StartVox()
	{
		if (!bManagerActive)
		{
			bManagerActive = true;
			OnPlayerTriggersEnabled.Broadcast(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void PauseActor(AHazeActor Actor, FInstigator Instigator)
	{
		bool bFoundActor = false;
		for (FHazeVoxPausedActor& PausedActor : PausedActors)
		{
			if (PausedActor.Actor == Actor)
			{
				// Already paused
				if (PausedActor.Instigators.Contains(Instigator))
					return;

				PausedActor.Instigators.Add(Instigator);
				bFoundActor = true;
				break;
			}
		}

		if (!bFoundActor)
		{
			FHazeVoxPausedActor NewPausedActor;
			NewPausedActor.Actor = Actor;
			NewPausedActor.Instigators.Add(Instigator);
			PausedActors.Add(NewPausedActor);
		}
		UHazeVoxRunner::Get().PauseActor(Actor);
	}

	UFUNCTION(BlueprintOverride)
	void ResumeActor(AHazeActor Actor, FInstigator Instigator)
	{
		bool bWasPaused = false;
		for (int i = PausedActors.Num() - 1; i >= 0; --i)
		{
			if (PausedActors[i].Actor == Actor)
			{
				bWasPaused = true;
				PausedActors[i].Instigators.RemoveSwap(Instigator);
				if (PausedActors[i].Instigators.IsEmpty())
				{
					PausedActors.RemoveAtSwap(i);
				}
				break;
			}
		}

		if (!bWasPaused)
			return;

		UHazeVoxRunner::Get().ResumeActor(Actor);
	}

	bool IsActorPaused(AHazeActor Actor) const
	{
		for (FHazeVoxPausedActor PausedActor : PausedActors)
		{
			if (PausedActor.Actor == Actor)
				return true;
		}
		return false;
	}

	void Stop(UHazeVoxAsset VoxAsset)
	{
		if (!IsValid(VoxAsset))
		{
			const FString ErrorMessage = f"HazeVoxController StopVoxAsset called with invalid VoxAsset: {VoxAsset}";
			TEMPORAL_LOG("Vox/Summary").Event(ErrorMessage);
			PrintError(ErrorMessage);
			return;
		}

		TEMPORAL_LOG("Vox/Summary").Event(f"Attempting to Stop {VoxAsset.Name}");

		UHazeVoxRunner VoxRunner = UHazeVoxRunner::Get();
		UVoxLane Lane = VoxRunner.FindLane(VoxAsset.Lane);
		Lane.StopAsset(VoxAsset);
	}

	void RegisterTriggerCallbacks(UObject Trigger, FName EnabledFunction, FName DisabledFunction)
	{
		OnPlayerTriggersEnabled.AddUFunction(Trigger, EnabledFunction);
		OnPlayerTriggersDisabled.AddUFunction(Trigger, DisabledFunction);
	}

	void UnregisterTriggerCallback(UObject Trigger)
	{
		OnPlayerTriggersEnabled.UnbindObject(Trigger);
		OnPlayerTriggersDisabled.UnbindObject(Trigger);
	}

	void TriggerPlayingStoppedDelegate(FOnHazeVoxAssetPlayingStopped Delegate, bool bInterrupted)
	{
		if (Delegate.IsBound())
		{
			FHazeVoxPlayingStoppedDelegateTrigger NewDelegate;
			NewDelegate.PlayingStoppedDelegate = Delegate;
			NewDelegate.bInterrupted = bInterrupted;
			PlayingStoppedDelegates.Add(NewDelegate);
		}
	}

	UFUNCTION(NetFunction)
	private void NetSetRandSeedSalt(int InRandSeedSalt)
	{
		RandSeedSalt = InRandSeedSalt;
		bSeedSaltSet = true;
	}

	private UVoxSharedRuntimeAsset FindOrAddSharedRuntimeAsset(UHazeVoxAsset VoxAsset)
	{
		UVoxSharedRuntimeAsset SharedAsset = nullptr;
		bool bFoundSharedAsset = SharedRuntimeAssets.Find(VoxAsset.Name, SharedAsset);
		if (!bFoundSharedAsset)
		{
			SharedAsset = UVoxSharedRuntimeAsset();
			SharedAsset.Init(VoxAsset, RandSeedSalt);

			// Restore PlayedOnce state if saved
			if (PersistentPlayedOnceVoxAssets.Contains(VoxAsset.Name))
			{
				SharedAsset.bPlayedOnce = true;
				SharedAsset.bAllPlayedOnce = true;
#if TEST
				VoxDebug::TemporalLogEvent(SharedAsset.TemporalLogPath, f"Restoring persistent PlayedOnce state for {SharedAsset.VoxAsset.Name}");
#endif
			}

			SharedRuntimeAssets.Add(VoxAsset.Name, SharedAsset);
		}
		return SharedAsset;
	}

	EVoxControllerCanTriggerResult MatchActorsAndCheckCanTrigger(UVoxSharedRuntimeAsset SharedAsset, TArray<AHazeActor> Actors, EHazeVoxLaneInterruptType InterruptType, TArray<AHazeActor>&out OutMatchingActors)
	{
		TArray<UHazeVoxCharacterTemplate> MatchingTemplates;
		for (auto Actor : Actors)
		{
			// Skip bad actors
			if (Actor == nullptr || Actor.IsActorBeingDestroyed())
				continue;

			auto CharacterTemplate = Actor.GetVoxCharacterTemplate();
			if (CharacterTemplate != nullptr)
			{
				if (SharedAsset.NeededCharacters.Contains(CharacterTemplate))
				{
					OutMatchingActors.AddUnique(Actor);
					MatchingTemplates.AddUnique(CharacterTemplate);
				}
			}
		}

		// Add global players if needed and not already added
		for (auto Template : SharedAsset.NeededCharacters)
		{
			if (Template.bIsPlayer && !MatchingTemplates.Contains(Template))
			{
				OutMatchingActors.AddUnique(Game::GetPlayer(Template.Player));
				MatchingTemplates.AddUnique(Template);
			}
		}

		// Update actor death/paused states
		for (AHazeActor Actor : OutMatchingActors)
		{
			CheckActorDeath(Actor);
		}

		int PreviewVoiceLineIndex = SharedAsset.PreviewNextStartIndex();
		EVoxControllerCanTriggerResult CanTriggerResult = CanAssetTrigger(SharedAsset, PreviewVoiceLineIndex, OutMatchingActors, MatchingTemplates, InterruptType);
		return CanTriggerResult;
	}

	private EVoxControllerCanTriggerResult CanAssetTrigger(UVoxSharedRuntimeAsset SharedAsset, int VoiceLineIndex, TArray<AHazeActor> Actors, TArray<UHazeVoxCharacterTemplate> Templates, EHazeVoxLaneInterruptType InterruptType) const
	{
		if (!VoxHelpers::InGame())
		{
#if TEST
			VoxDebug::TemporalLogEvent(SharedAsset.TemporalLogPath, f"{SharedAsset.VoxAsset.Name} can't trigger, InGame check failed");
#endif
			return EVoxControllerCanTriggerResult::FullyBlocked;
		}

		if (bExternalPause)
		{
#if TEST
			VoxDebug::TemporalLogEvent(SharedAsset.TemporalLogPath, f"{SharedAsset.VoxAsset.Name} can't trigger, External Pause enabled");
#endif
			return EVoxControllerCanTriggerResult::FullyBlocked;
		}

		bool bSharedCanTrigger = SharedAsset.CanTrigger();
		if (!bSharedCanTrigger)
			return EVoxControllerCanTriggerResult::FullyBlocked;

		bool bMissingTemplates = false;
		for (auto NeededTemplate : SharedAsset.NeededCharacters)
		{
			if (!Templates.Contains(NeededTemplate))
			{
				bMissingTemplates = true;
#if TEST
				FString ErrorMessage = f"{SharedAsset.VoxAsset.Name} can't trigger, missing actor with Character Template {NeededTemplate.CharacterName}";
				VoxDebug::TemporalLogEvent(SharedAsset.TemporalLogPath, ErrorMessage);
				PrintError(ErrorMessage);
#endif
			}
		}

		if (bMissingTemplates)
			return EVoxControllerCanTriggerResult::FullyBlocked;

		AHazeActor VoiceLineActor = VoxAssetHelpers::FindVoiceLineActor(SharedAsset.VoxAsset.VoiceLines[VoiceLineIndex].CharacterTemplate, Actors);
		if (IsActorPaused(VoiceLineActor) && !SharedAsset.VoxAsset.bPlayDuringPaused)
		{
#if TEST
			VoxDebug::TemporalLogEvent(SharedAsset.TemporalLogPath, f"{SharedAsset.VoxAsset.Name} can't trigger, actor is paused {VoiceLineActor}");
#endif
			return EVoxControllerCanTriggerResult::BlockedButCanQueue;
		}

		if (InterruptType == EHazeVoxLaneInterruptType::None || InterruptType == EHazeVoxLaneInterruptType::SameAndLower)
		{
			int BlockingLaneIndex = UHazeVoxRunner::Get().FindBlockingLane(SharedAsset.VoxAsset.Lane, VoiceLineActor);
			if (BlockingLaneIndex > -1)
			{
#if TEST
				VoxDebug::TemporalLogEvent(SharedAsset.TemporalLogPath, f"{SharedAsset.VoxAsset.Name} can't trigger, blocked by lane {EHazeVoxLaneName(BlockingLaneIndex)}");
#endif
				return EVoxControllerCanTriggerResult::BlockedButCanQueue;
			}
		}
		else if (InterruptType == EHazeVoxLaneInterruptType::GenericsAndLower)
		{
			const int GenericIndex = int(EHazeVoxLaneName::Generics);
			const int LaneIndex = int(SharedAsset.VoxAsset.Lane);
			const int CheckIndex = Math::Min(GenericIndex, LaneIndex);
			int BlockingLaneIndex = UHazeVoxRunner::Get().FindBlockingLane(EHazeVoxLaneName(CheckIndex), VoiceLineActor);
			if (BlockingLaneIndex > -1)
			{
#if TEST
				VoxDebug::TemporalLogEvent(SharedAsset.TemporalLogPath, f"{SharedAsset.VoxAsset.Name} can't trigger with Lane Interrupt, blocked by lane {EHazeVoxLaneName(BlockingLaneIndex)}");
#endif
				return EVoxControllerCanTriggerResult::BlockedButCanQueue;
			}
		}

		return EVoxControllerCanTriggerResult::CanTrigger;
	}

	private void ToggleExternalPause(bool bPaused)
	{
		const FString Message = f"HazeVoxController External Paused {bPaused}";
		TEMPORAL_LOG("Vox/Summary").Event(Message);

		bExternalPause = bPaused;
		UHazeVoxRunner::Get().SetExternalPause(bExternalPause);
	}

	// ---------------------- Debug stuff ----------------------

#if TEST
	private int DebugTriggerId = 1;
	int NextDebugTriggerId()
	{
		int NewId = DebugTriggerId;
		DebugTriggerId++;
		return NewId;
	}

	void DebugTemporalLog()
	{
		for (TMapIterator<FName, UVoxSharedRuntimeAsset>& SharedAssetIt : SharedRuntimeAssets)
		{
			UVoxSharedRuntimeAsset SharedAsset = SharedAssetIt.GetValue();
			if (SharedAsset.Cooldown > 0.0)
			{
				TEMPORAL_LOG(SharedAsset.TemporalLogPath).Value(f"OnCooldown;{SharedAsset.VoxAsset.Name}", SharedAsset.Cooldown);
			}
		}

		auto VoTimersComponent = UGlobalVoTimersPlayerComponent::GetOrCreate(Game::GetMio());
		VoTimersComponent.DebugTemporalLog();

		auto VoRateLimitsComponent = UGlobalVoRateLimitPlayerComponent::GetOrCreate(Game::GetMio());
		VoRateLimitsComponent.DebugTemporalLog();
	}

	void OnTickDebugPlay(FName VoxAssetName)
	{
		if (DebugPlayOnTicks.Num() <= 0)
			return;

		DebugPlayOnTicks.Last().VoxAssetPlayed.FindOrAdd(VoxAssetName, 0) += 1;
	}

	void OnTickDebugUpdate()
	{
		TMap<FName, int32> VoxAssetPlayed;
		for (int i = 0; i < DebugPlayOnTicks.Num(); ++i)
		{
			for (auto Played : DebugPlayOnTicks[i].VoxAssetPlayed)
			{
				VoxAssetPlayed.FindOrAdd(Played.Key, 0) += 1;
			}
		}

		for (auto FramePlayed : VoxAssetPlayed)
		{
			const int32 MaxExpected = Math::Max(Math::IntegerDivisionTrunc(DebugPlayOnTicks.Num(), 2), 2);
			if (FramePlayed.Value > MaxExpected)
			{
				if (DebugPlayOnTickIgnored.Contains(FramePlayed.Key))
					continue;

				PrintError(f"VoxAsset play on tick: {FramePlayed.Key}", 20.0f);
				DebugPlayOnTickIgnored.AddUnique(FramePlayed.Key);
			}
		}

		DebugPlayOnTicks.Add(FHazeVoxDebugPlayOnTickItem());
		while (DebugPlayOnTicks.Num() >= DebugPlayOnTickNumFrames)
		{
			DebugPlayOnTicks.RemoveAt(0);
		}
	}

#endif
};

namespace UHazeVoxController
{
	UHazeVoxController Get()
	{
		return Game::GetSingleton(UHazeVoxController);
	}
};
