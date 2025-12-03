
namespace VoxAssetHelpers
{
	AHazeActor FindVoiceLineActor(UHazeVoxCharacterTemplate Template, TArray<AHazeActor> TemplateActors)
	{
		for (auto Actor : TemplateActors)
		{
			if (Actor.GetVoxCharacterTemplate() == Template)
			{
				return Actor;
			}
		}

		if (Template.bIsPlayer)
		{
			return Game::GetPlayer(Template.Player);
		}

		return nullptr;
	}
}

enum EVoxStoppedReason
{
	Interrupted,
	NotTriggered
}

enum EVoxRuntimeState
{
	Stopped,
	Queued,
	Playing,
	TailingOut
};

class UVoxRuntimeAsset
{
	UVoxSharedRuntimeAsset SharedAsset;
	UHazeVoxAsset VoxAsset;

	EVoxRuntimeState State = EVoxRuntimeState::Stopped;
	TArray<AHazeActor> TemplateActors;

	EHazeVoxLaneInterruptType LaneInterruptType = EHazeVoxLaneInterruptType::None;
	bool bInterruptBothPlayers = true;

	private float QueueTimer = 0.0;

	private TArray<UVoxVoiceLine> ActiveVoiceLines;
	private int WaitingForNextVoiceLineIndex = -1;

#if TEST
	private FString TemporalLogPath;
	private int DebugTriggerId = -1;
#endif

	private FOnHazeVoxAssetPlayingStopped OnPlayingStopped;
	private TOptional<bool> SavedInterruption;

	private bool bUseConversationRTPC = false;

	void Init(UVoxSharedRuntimeAsset InSharedAsset, const TArray<AHazeActor>& InActors, FOnHazeVoxAssetPlayingStopped PlayingStoppedDelegate)
	{
		SharedAsset = InSharedAsset;
		TemplateActors = InActors;

#if TEST
		TemporalLogPath = SharedAsset.TemporalLogPath;
#endif

		VoxAsset = SharedAsset.VoxAsset;

		OnPlayingStopped = PlayingStoppedDelegate;

		bUseConversationRTPC = false;

		if (VoxAsset.Type == EHazeVoxAssetType::Dialogue)
		{
			bool bHasMio = false;
			bool bHasZoe = false;
			bool bHasNPC = false;

			for (const AHazeActor Actor : InActors)
			{
				const AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
				if (Player != nullptr)
				{
					bHasMio = bHasMio || Player.IsMio();
					bHasZoe = bHasZoe || Player.IsZoe();
				}
				else
				{
					bHasNPC = true;
				}
			}

			const bool bBothplayers = bHasMio && bHasZoe;
			const bool bPlayerAndNPC = (bHasMio || bHasZoe) && bHasNPC;
			bUseConversationRTPC = bBothplayers || bPlayerAndNPC;
		}
	}

	void SetLaneInterrupt(EHazeVoxLaneInterruptType InLaneInterruptType, bool bInInterruptBothPlayers)
	{
		LaneInterruptType = InLaneInterruptType;
		bInterruptBothPlayers = bInInterruptBothPlayers;
	}

	void Tick(float DeltaTime)
	{
		// Remove template actors that has become invalid
		for (int i = TemplateActors.Num() - 1; i >= 0; --i)
		{
			if (!IsValid(TemplateActors[i]) || TemplateActors[i].IsActorBeingDestroyed())
			{
				TemplateActors.RemoveAtSwap(i);
#if TEST
				VoxDebug::TemporalLogEvent(TemporalLogPath, f"Invalid actor in TemplateActors");
#endif
			}
		}

		switch (State)
		{
			case EVoxRuntimeState::Stopped:
			case EVoxRuntimeState::Queued:
			{
				break;
			}
			case EVoxRuntimeState::Playing:
			{
				UpdateVoiceLines(DeltaTime);
				break;
			}
			case EVoxRuntimeState::TailingOut:
			{
				UpdateTailingOut(DeltaTime);
				break;
			}
		}
	}

	bool TickQueue(float DeltaTime)
	{
		if (State != EVoxRuntimeState::Queued)
			return false;

		QueueTimer -= DeltaTime;
		if (QueueTimer <= 0.0)
		{
			TriggerInterruptedDelegates();
			State = EVoxRuntimeState::Stopped;
			return false;
		}

		return true;
	}

	void Stop(bool bTriggerDelegates = true)
	{
		if (bTriggerDelegates)
		{
			TriggerInterruptedDelegates();
		}

		for (auto& VL : ActiveVoiceLines)
		{
#if TEST
			VoxDebug::TemporalLogEvent(TemporalLogPath, f"{VoxAsset.Name} stopping VoiceLine {VL.VoiceLineIndex}:{VoxAsset.VoiceLines[VL.VoiceLineIndex].AudioEvent.Name}");
#endif
			VL.Stop();
		}

		ActiveVoiceLines.Reset();
		TemplateActors.Reset();
		OnPlayingStopped.Clear();

		State = EVoxRuntimeState::Stopped;
		SharedAsset.AutoTickCooldown();

		if (bUseConversationRTPC)
		{
			UHazeVoxRunner::Get().StopVoxRtpc(HazeVoxRtpcs::CoversationDucking, this);
		}
	}

	void TriggerInterruptedDelegates(bool bInterrupted = true)
	{
		// Trigger from controller so it gets executed on next tick
		UHazeVoxController::Get().TriggerPlayingStoppedDelegate(OnPlayingStopped, bInterrupted);

		// Clear delegate to ensure it never runs more than once
		OnPlayingStopped.Clear();

		if (bInterrupted)
			VoxDebug::TelemetryVoxAsset(n"vox_interrupted", VoxAsset);
	}

	void Play(int InVoiceLineIndex, bool bFromQueue)
	{
#if TEST
		VoxDebug::TemporalLogEvent(TemporalLogPath, f"Playing {VoxAsset.Name}");
		DebugTriggerId = UHazeVoxController::Get().NextDebugTriggerId();
#endif

		if (State == EVoxRuntimeState::Playing || State == EVoxRuntimeState::TailingOut)
			Stop();

		AHazeActor PlayActor = VoxAssetHelpers::FindVoiceLineActor(VoxAsset.VoiceLines[InVoiceLineIndex].CharacterTemplate, TemplateActors);
		if (PlayActor == nullptr)
		{
			devError(f"Failed to find actor for VL {InVoiceLineIndex} for {VoxAsset.Name}");
			TriggerInterruptedDelegates();
			return;
		}

		StartVoiceLine(InVoiceLineIndex, PlayActor, bFromQueue);
		State = EVoxRuntimeState::Playing;
		SharedAsset.bPlayedOnce = true;

		// Update AllPlayed for dialogues in case there is only one line
		if (VoxAsset.Type == EHazeVoxAssetType::Dialogue)
			SharedAsset.UpdateDialogueAllPlayed(InVoiceLineIndex);

		SharedAsset.ResetCooldown();
	}

	void PlacedInQueue()
	{
		if (!IsStopped())
		{
			devError("VoxRuntimeAsset queued while playing!");
			Stop();
			return;
		}

		QueueTimer = VoxAsset.LifetimeInQueue;
		State = EVoxRuntimeState::Queued;
	}

	void Pause(AHazeActor Actor)
	{
		if (State != EVoxRuntimeState::Playing)
			return;

		if (VoxAsset.ResumeAfterPause)
		{
			for (UVoxVoiceLine VL : ActiveVoiceLines)
			{
				if (VL.Actor == Actor)
					VL.Pause();
			}
		}
		else
		{
			Stop();
		}
	}

	void Resume(AHazeActor Actor)
	{
		if (State != EVoxRuntimeState::Playing)
			return;

		for (UVoxVoiceLine VL : ActiveVoiceLines)
		{
			if (VL.Actor == Actor)
				VL.ResumeWithSeek();
		}
	}

	void HardPause()
	{
		for (UVoxVoiceLine VL : ActiveVoiceLines)
		{
			VL.HardPause();
		}
	}

	void HardResume()
	{
		for (UVoxVoiceLine VL : ActiveVoiceLines)
		{
			VL.HardResume();
		}
	}

	bool IsStopped() const
	{
		return State == EVoxRuntimeState::Stopped || State == EVoxRuntimeState::Queued;
	}

	bool IsBlockingActors(TArray<AHazeActor> Actors, bool bPausedAsActive) const
	{
		if (IsStopped())
			return false;

		for (auto Actor : Actors)
		{
			if (IsActorActive(Actor, bPausedAsActive))
				return true;
		}
		return false;
	}

	bool IsActorActive(AHazeActor Actor, bool bPausedAsActive) const
	{
		for (auto VL : ActiveVoiceLines)
		{
			if (!VL.IsPlaying())
				continue;

			if (!bPausedAsActive && VL.bPaused)
				continue;

			if (VL.Actor == Actor)
				return true;
		}
		return false;
	}

	bool IsTailingOut() const
	{
		return State == EVoxRuntimeState::TailingOut;
	}

	bool CanQueue() const
	{
		return State == EVoxRuntimeState::Stopped;
	}

	void GetActiveActors(TArray<AHazeActor>& OutActiveActors, bool bPausedAsActive) const
	{
		for (auto VL : ActiveVoiceLines)
		{
			if (!bPausedAsActive && VL.bPaused)
				continue;

			OutActiveActors.AddUnique(VL.Actor);
		}
	}

	void GetTemplateActors(TArray<AHazeActor>& OutActors) const
	{
		OutActors.Append(TemplateActors);
	}

	UHazeVoxAsset GetVoxAsset() const
	{
		return VoxAsset;
	}

	private void UpdateVoiceLines(float DeltaTime)
	{
		for (UVoxVoiceLine VoiceLine : ActiveVoiceLines)
		{
			VoiceLine.Tick(DeltaTime);
		}

		// Update tailing out
		bool bAllTailingOut = true;
		for (const UVoxVoiceLine VoiceLine : ActiveVoiceLines)
		{
			if (VoiceLine.State != ERuntimeVoiceLineState::TailingOut)
			{
				bAllTailingOut = false;
			}
		}

		if (bAllTailingOut)
		{
			State = EVoxRuntimeState::TailingOut;
			if (bUseConversationRTPC)
			{
				UHazeVoxRunner::Get().StopVoxRtpc(HazeVoxRtpcs::CoversationDucking, this);
			}
		}

		int NextDialogueIndex = -1;
		if (VoxAsset.Type == EHazeVoxAssetType::Dialogue)
		{
			UVoxVoiceLine LastVoiceLine = ActiveVoiceLines.Last();
			if (LastVoiceLine.ConsumeTriggerNext())
			{
				NextDialogueIndex = SharedAsset.GetNextDialogueIndex(LastVoiceLine.VoiceLineIndex);
			}
		}

		// Remove finished lines
		int VoiceLineIndex = 0;
		while (VoiceLineIndex < ActiveVoiceLines.Num())
		{
			if (ActiveVoiceLines[VoiceLineIndex].State == ERuntimeVoiceLineState::Stopped)
			{
				if (ActiveVoiceLines[VoiceLineIndex].AudioEmitter != nullptr)
					Audio::ReturnPooledEmitter(ActiveVoiceLines[VoiceLineIndex], ActiveVoiceLines[VoiceLineIndex].AudioEmitter);
				ActiveVoiceLines.RemoveAt(VoiceLineIndex);
			}
			else
			{
				VoiceLineIndex++;
			}
		}

		// Trigger next dialogue line if valid and not first index
		if (NextDialogueIndex > 0)
		{
			PlayNextDialogueIndex(NextDialogueIndex);
		}

		// Is asset stopped?
		if (ActiveVoiceLines.Num() <= 0)
		{
			// Get the saved interruption state if we have one, default to false otherwise
			const bool bInterrupted = SavedInterruption.Get(false);
			TriggerInterruptedDelegates(bInterrupted);

			if (bUseConversationRTPC)
			{
				UHazeVoxRunner::Get().StopVoxRtpc(HazeVoxRtpcs::CoversationDucking, this);
			}

			TemplateActors.Reset();
			State = EVoxRuntimeState::Stopped;
			SharedAsset.AutoTickCooldown();
			return;
		}

		// This will only happen once, the line will be moved to only tick tailing out after this
		if (State == EVoxRuntimeState::TailingOut)
		{
			TriggerInterruptedDelegates();

			// Tick cooldown when all is TailingOut
			if (SharedAsset.Cooldown > 0.0)
				SharedAsset.TickCooldown(DeltaTime);
		}
	}

	private void UpdateTailingOut(float DeltaTime)
	{
		for (UVoxVoiceLine VoiceLine : ActiveVoiceLines)
		{
			VoiceLine.Tick(DeltaTime);
		}

		// Remove finished lines
		int VoiceLineIndex = 0;
		while (VoiceLineIndex < ActiveVoiceLines.Num())
		{
			if (ActiveVoiceLines[VoiceLineIndex].State == ERuntimeVoiceLineState::Stopped)
			{
				if (ActiveVoiceLines[VoiceLineIndex].AudioEmitter != nullptr)
					Audio::ReturnPooledEmitter(ActiveVoiceLines[VoiceLineIndex], ActiveVoiceLines[VoiceLineIndex].AudioEmitter);
				ActiveVoiceLines.RemoveAt(VoiceLineIndex);
			}
			else
			{
				VoiceLineIndex++;
			}
		}

		if (ActiveVoiceLines.Num() <= 0)
		{
			TemplateActors.Reset();
			State = EVoxRuntimeState::Stopped;
			SharedAsset.AutoTickCooldown();
			return;
		}

		// Tick cooldown when all is TailingOut
		if (SharedAsset.Cooldown > 0.0)
			SharedAsset.TickCooldown(DeltaTime);
	}

	private void PlayNextDialogueIndex(int NextDialogueIndex)
	{
		// Check actor
		AHazeActor PlayActor = VoxAssetHelpers::FindVoiceLineActor(VoxAsset.VoiceLines[NextDialogueIndex].CharacterTemplate, TemplateActors);
		if (PlayActor == nullptr)
		{
#if TEST
			VoxDebug::TemporalLogEvent(TemporalLogPath, f"Cant trigger next VO, failed to find actor for VL {NextDialogueIndex}");
#endif
			SavedInterruption.Set(true);
			return;
		}

		auto VoxController = UHazeVoxController::Get();

		// Check if actor is paused
		bool bActorPaused = VoxController.IsActorPaused(PlayActor);
		if (bActorPaused && !VoxAsset.bPlayDuringPaused && !VoxAsset.ResumeAfterPause)
		{
#if TEST
			VoxDebug::TemporalLogEvent(TemporalLogPath, f"Cant trigger next VO, actor is paused {PlayActor}");
#endif
			SavedInterruption.Set(true);
			return;
		}

		// Check if another lane is blocked
		int BlockingLaneIndex = UHazeVoxRunner::Get().FindBlockingLane(VoxAsset.Lane, PlayActor);
		if (BlockingLaneIndex >= 0)
		{
#if TEST
			VoxDebug::TemporalLogEvent(TemporalLogPath, f"Cant trigger next VO, blocked by other lane {BlockingLaneIndex}");
#endif
			SavedInterruption.Set(true);
			return;
		}

		// Trigger next line
		SharedAsset.UpdateDialogueAllPlayed(NextDialogueIndex);
		StartVoiceLine(NextDialogueIndex, PlayActor, false);
		State = EVoxRuntimeState::Playing;

		// Reset any interruption since we are playing something now
		SavedInterruption.Reset();

		// Immediately pause if paused
		if (bActorPaused && VoxAsset.ResumeAfterPause)
		{
			Pause(PlayActor);
		}
	}

	private void StartVoiceLine(int VoiceLineIndex, AHazeActor Actor, bool bFromQueue)
	{
#if TEST
		VoxDebug::TemporalLogEvent(TemporalLogPath, f"{VoxAsset.Name} starting VoiceLine {VoiceLineIndex}:{VoxAsset.VoiceLines[VoiceLineIndex].AudioEvent.Name}");
#endif

		ActiveVoiceLines.Add(UVoxVoiceLine(VoxAsset, VoiceLineIndex, Actor));
		ActiveVoiceLines.Last().Init();
		ActiveVoiceLines.Last().Play(bFromQueue);

		if (bUseConversationRTPC)
		{
			// This uses instigators so we can enable this on every play, not just the first one
			UHazeVoxRunner::Get().StartVoxRtpc(HazeVoxRtpcs::CoversationDucking, this);
		}
	}

	// ---------------------- Debug stuff ----------------------

#if TEST
	FLinearColor DebugStateColor() const
	{
		switch (State)
		{
			case EVoxRuntimeState::Stopped:
				return FLinearColor::White;
			case EVoxRuntimeState::Queued:
				return FLinearColor::Gray;
			case EVoxRuntimeState::Playing:
				return FLinearColor::Green;
			case EVoxRuntimeState::TailingOut:
				return FLinearColor::Teal;
		}
	}

	FVoxDebugRuntimeAsset BuildDebugInfo() const
	{
		if (!IsValid(VoxAsset))
			return FVoxDebugRuntimeAsset();

		FVoxDebugRuntimeAsset DebugRuntimeAsset;
		DebugRuntimeAsset.Name = VoxAsset.Name.ToString();
		DebugRuntimeAsset.DebugTriggerId = DebugTriggerId;
		DebugRuntimeAsset.State = f"{State}";
		DebugRuntimeAsset.Color = DebugStateColor();
		for (auto VL : ActiveVoiceLines)
		{
			DebugRuntimeAsset.VoiceLines.Add(VL.BuildDebugInfo());
		}
		return DebugRuntimeAsset;
	}

	void DebugTemporalLog(FTemporalLog& TemporalLog, FString ParentPrefix) const
	{
		TemporalLog.CustomStatus(f"{ParentPrefix};State", f"{State}", DebugStateColor());
		TemporalLog.Value(f"{ParentPrefix};Type", VoxAsset.Type);
		TemporalLog.Value(f"{ParentPrefix};Asset", VoxAsset.Name);
		TemporalLog.Value(f"{ParentPrefix};Priority", VoxAsset.Priority);
		TemporalLog.Value(f"{ParentPrefix};(Shared)PlayedOnce", SharedAsset.bPlayedOnce);
		TemporalLog.Value(f"{ParentPrefix};(Shared)AllPlayedOnce", SharedAsset.bAllPlayedOnce);
		TemporalLog.Value(f"{ParentPrefix};(Shared)Cooldown", SharedAsset.Cooldown);

		for (auto VL : ActiveVoiceLines)
		{
			VL.DebugTemporalLog(TemporalLog, ParentPrefix);
		}
	}

	void DebugTemporalLogQueue(FTemporalLog& TemporalLog, FString ParentPrefix) const
	{
		TemporalLog.CustomStatus(f"{ParentPrefix};State", f"{State}", DebugStateColor());
		TemporalLog.Value(f"{ParentPrefix};Type", VoxAsset.Type);
		TemporalLog.Value(f"{ParentPrefix};Priority", VoxAsset.Priority);
		TemporalLog.Value(f"{ParentPrefix};QueueTimer", QueueTimer);
	}

	void DebugTemporalLogSummary(FTemporalLog& TemporalLog, FString ParentPrefix) const
	{
		TemporalLog.CustomStatus(f"{ParentPrefix};State", f"{State}", DebugStateColor());
		TemporalLog.Value(f"{ParentPrefix};Asset", VoxAsset.Name);
	}
#endif
}
