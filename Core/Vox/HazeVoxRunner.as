

namespace HazeVoxRtpcs
{
	const FName CoversationDucking = n"Rtpc_Conversation_Ducking";
	const FName MuteEffortsMio = n"Rtpc_MuteActionEfforts_Mio";
	const FName MuteEffortsZoe = n"Rtpc_MuteActionEfforts_Zoe";
}

struct FHazeVoxRtpcInstigators
{
	TArray<FInstigator> Instigators;
}

class UHazeVoxRunner : UHazeVoxRunnerBaseSingleton
{
	const FHazeAudioID ConversationRtpcId = FHazeAudioID("Rtpc_VO_Shared_Conversation_Ducking");
	const FHazeAudioID MuteEffortsMioId = FHazeAudioID("Rtpc_VO_Efforts_Shared_MuteActionEfforts_Mio");
	const FHazeAudioID MuteEffortsZoeId = FHazeAudioID("Rtpc_VO_Efforts_Shared_MuteActionEfforts_Zoe");

	TArray<UVoxLane> Lanes;

	private bool bExternalPause = false;

	private TMap<FName, FHazeVoxRtpcInstigators> RtpcInstigators;

	private TMap<FName, FHazeAudioID> VoxRtpcs;
	default VoxRtpcs.Add(HazeVoxRtpcs::CoversationDucking, ConversationRtpcId);
	default VoxRtpcs.Add(HazeVoxRtpcs::MuteEffortsMio, MuteEffortsMioId);
	default VoxRtpcs.Add(HazeVoxRtpcs::MuteEffortsZoe, MuteEffortsZoeId);

#if TEST
	bool bTrackPlayingEvents = false;
	TArray<FVoxDevTimelineLane> DebugTimelineLanes;
	uint DebugStartFrame = 0;
#endif

	UFUNCTION(BlueprintOverride)
	void Initialize()
	{
		InitLanes();

		// Reset on start for extra safety
		ResetRTPC();

#if TEST
		const auto DebugConfig = Cast<UHazeVoxDebugConfig>(UHazeVoxDebugConfig.DefaultObject);
		bTrackPlayingEvents = DebugConfig.bTrackPlayingEvents;
#endif
	}

	UFUNCTION(BlueprintOverride)
	void Shutdown()
	{
		ResetRTPC();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!VoxHelpers::InGame())
			return;

		if (bExternalPause)
			return;

		for (auto Lane : Lanes)
		{
			Lane.Tick(DeltaTime);

			// Advance queue
			if (!Lane.IsPlaying())
			{
				FVoxLaneQueueItem QueueItem;
				if (Lane.GetNextInQueue(QueueItem))
				{
					int VoiceLineIndex = QueueItem.RuntimeAsset.SharedAsset.GetNextIndex();
					PlayLocal(QueueItem.RuntimeAsset, VoiceLineIndex, true);
				}
			}
		}

		// Check blocking lanes for all lanes in case playing actor in each lane has changed
		for (auto Lane : Lanes)
		{
			if (Lane.IsPlaying())
			{
				StopBlockedLanes(Lane);
			}
		}

#if TEST
		DebugTemporalLog();

		if (bTrackPlayingEvents)
		{
			LogFrameDebug();
		}
#endif
	}

	UVoxLane FindLane(EHazeVoxLaneName LaneName)
	{
		int LaneIndex = int(LaneName);
		if (!Lanes.IsValidIndex(LaneIndex))
		{
			PrintError("Invalid LaneName " + LaneName);
			return nullptr;
		}
		return Lanes[LaneIndex];
	}

	int FindBlockingLane(EHazeVoxLaneName Lane, AHazeActor Actor) const
	{
		int CurrentLaneIndex = int(Lane);
		for (int LaneIndex = 0; LaneIndex < CurrentLaneIndex; ++LaneIndex)
		{
			if (Lanes[LaneIndex].IsBlockingActor(Actor))
			{
				return LaneIndex;
			}
		}
		return -1;
	}

	bool IsActorActive(AHazeActor Actor) const
	{
		for (const UVoxLane Lane : Lanes)
		{
			if (Lane.IsBlockingActor(Actor))
				return true;
		}
		return false;
	}

	void PlayLocal(UVoxRuntimeAsset RuntimeAsset, int VoiceLineIndex, bool bFromQueue)
	{
		UVoxLane Lane = FindLane(RuntimeAsset.GetVoxAsset().Lane);
		StopBlockedLanes(Lane);

		if (RuntimeAsset.LaneInterruptType != EHazeVoxLaneInterruptType::None)
		{
			InterruptLanesSpecial(RuntimeAsset, VoiceLineIndex);
		}

		Lane.Play(RuntimeAsset, VoiceLineIndex, bFromQueue);

		VoxDebug::TelemetryVoxAsset(n"vox_starting", RuntimeAsset.VoxAsset, f"{bFromQueue}");
	}

	void Reset()
	{
		for (auto Lane : Lanes)
		{
			Lane.ResetLane();
		}

		ResetRTPC();
	}

	void ResetRTPC()
	{
		RtpcInstigators.Reset();

		// Safety stop all RTPCs
		AudioComponent::SetGlobalRTPC(ConversationRtpcId, 0.0, 0.0);
		AudioComponent::SetGlobalRTPC(MuteEffortsMioId, 0.0, 0.0);
		AudioComponent::SetGlobalRTPC(MuteEffortsZoeId, 0.0, 0.0);
	}

	void PauseActor(AHazeActor Actor)
	{
		for (int LaneIndex = 0; LaneIndex < Lanes.Num(); ++LaneIndex)
		{
			bool bPaused = Lanes[LaneIndex].PauseUsingActor(Actor);
			if (bPaused)
				break;
		}
	}

	void ResumeActor(AHazeActor Actor)
	{
		for (int LaneIndex = 0; LaneIndex < Lanes.Num(); ++LaneIndex)
		{
			bool bPaused = Lanes[LaneIndex].ResumeUsingActor(Actor);
			if (bPaused)
				break;
		}
	}

	void SetExternalPause(bool bPaused)
	{
		bExternalPause = bPaused;
		for (UVoxLane Lane : Lanes)
		{
			Lane.ToggleHardPause(bPaused);
		}
	}

	void StartVoxRtpc(FName RtpcName, FInstigator Instigator)
	{
		if (!devEnsure(VoxRtpcs.Contains(RtpcName), f"Invalid Vox Rtpc Name {RtpcName}"))
			return;

		if (RtpcInstigators.Contains(RtpcName))
		{
			RtpcInstigators[RtpcName].Instigators.AddUnique(Instigator);
		}
		else
		{
			FHazeVoxRtpcInstigators NewInstigators;
			NewInstigators.Instigators.Add(Instigator);
			RtpcInstigators.Add(RtpcName, NewInstigators);

			AudioComponent::SetGlobalRTPC(VoxRtpcs[RtpcName], 1.0, 300.0);
		}
	}

	void StopVoxRtpc(FName RtpcName, FInstigator Instigator)
	{
		if (!devEnsure(VoxRtpcs.Contains(RtpcName), f"Invalid Vox Rtpc Name {RtpcName}"))
			return;

		if (RtpcInstigators.Contains(RtpcName))
		{
			const int NumRemoved = RtpcInstigators[RtpcName].Instigators.RemoveSwap(Instigator);
			if (NumRemoved > 0 && RtpcInstigators[RtpcName].Instigators.IsEmpty())
			{
				RtpcInstigators.Remove(RtpcName);

				AudioComponent::SetGlobalRTPC(VoxRtpcs[RtpcName], 0.0, 300.0);
			}
		}
	}

	private void StopBlockedLanes(UVoxLane Lane)
	{
		TArray<AHazeActor> LaneActors;
		Lane.GetActiveActors(LaneActors, false);

		if (LaneActors.Num() <= 0)
			return;

		int StartLaneIndex = int(Lane.LaneName) + 1;
		for (int LaneIndex = StartLaneIndex; LaneIndex < Lanes.Num(); ++LaneIndex)
		{
			Lanes[LaneIndex].StopIfBlocked(LaneActors);
		}
	}

	private void InterruptLanesSpecial(UVoxRuntimeAsset RuntimeAsset, int VoiceLineIndex)
	{
		if (!devEnsure(RuntimeAsset.LaneInterruptType != EHazeVoxLaneInterruptType::None))
			return;

		EHazeVoxLaneName StartLane = EHazeVoxLaneName::Generics;
		if (RuntimeAsset.LaneInterruptType == EHazeVoxLaneInterruptType::SameAndLower)
		{
			StartLane = RuntimeAsset.VoxAsset.Lane;
		}

		TArray<AHazeActor> BlockingActors;
		if (RuntimeAsset.bInterruptBothPlayers)
		{
			BlockingActors.Add(Game::GetMio());
			BlockingActors.Add(Game::GetZoe());
		}
		else
		{
			TArray<AHazeActor> TemplateActors;
			RuntimeAsset.GetTemplateActors(TemplateActors);
			AHazeActor PlayActor = VoxAssetHelpers::FindVoiceLineActor(RuntimeAsset.VoxAsset.VoiceLines[VoiceLineIndex].CharacterTemplate, TemplateActors);
			BlockingActors.Add(PlayActor);
		}

		int StartLaneIndex = int(StartLane);
		for (int LaneIndex = StartLaneIndex; LaneIndex < Lanes.Num(); ++LaneIndex)
		{
			Lanes[LaneIndex].StopIfBlocked(BlockingActors);
		}
	}

	private void InitLanes()
	{
		Lanes.Reset();
		Lanes.Add(UVoxLane(EHazeVoxLaneName::First, 1));
		Lanes.Add(UVoxLane(EHazeVoxLaneName::Second, 1));
		Lanes.Add(UVoxLane(EHazeVoxLaneName::Third, 1));
		Lanes.Add(UVoxLane(EHazeVoxLaneName::Generics, 3));
		Lanes.Add(UVoxLane(EHazeVoxLaneName::EnemyCombat, 10, EVoxLaneSlotSortType::PriorityAge));
		Lanes.Add(UVoxLane(EHazeVoxLaneName::Efforts, 10, EVoxLaneSlotSortType::PriorityAge));
	}

	// ---------------------- Debug stuff ----------------------

#if TEST
	void DebugTemporalLog()
	{
		FTemporalLog TemporalLog = TEMPORAL_LOG("Vox");
		FTemporalLog Summary = TemporalLog.Page("Summary");
		Summary.Value("bExternalPause", bExternalPause);
		for (auto Lane : Lanes)
		{
			Lane.DebugTemporalLogSummary(Summary);
			Lane.DebugTemporalLog(TemporalLog);
		}

		FString RtpcText = "None";
		if (RtpcInstigators.Num() > 0)
		{
			RtpcText = "";
			for (auto KV : RtpcInstigators)
			{
				RtpcText += KV.GetKey().ToString();
			}
		}
		Summary.Value("Active RTPCs", RtpcText);
	}

	void SetupDebugTimelineLanes()
	{
		DebugTimelineLanes.Reset();

		// Setup lanes with slots
		for (const UVoxLane Lane : Lanes)
		{
			FVoxDevTimelineLane NewLane;
			NewLane.Name = VoxHelpers::BuildLaneDebugName(Lane.LaneName);
			NewLane.LaneName = Lane.LaneName;

			for (int i = 0; i < Lane.NumSlots; ++i)
			{
				NewLane.Slots.Add(FVoxDevTimelineLaneSlot());
			}
			DebugTimelineLanes.Add(NewLane);
		}
	}

	void LogFrameDebug()
	{
		if (DebugTimelineLanes.Num() <= 0)
		{
			SetupDebugTimelineLanes();
			DebugStartFrame = GFrameNumber;
		}

		TArray<FVoxDebugLane> DebugLanes;
		for (auto Lane : Lanes)
		{
			DebugLanes.Add(Lane.BuildDebugInfo());
		}

		int CurrentFrame = int(GFrameNumber);
		float GameTime = Time::GetGameTimeSeconds();

		for (int LaneIndex = 0; LaneIndex < DebugLanes.Num(); ++LaneIndex)
		{
			const FVoxDebugLane& Lane = DebugLanes[LaneIndex];
			FVoxDevTimelineLane& TimelineLane = DebugTimelineLanes[LaneIndex];

			for (int SlotIndex = 0; SlotIndex < Lane.Assets.Num(); ++SlotIndex)
			{
				const FVoxDebugRuntimeAsset& Asset = Lane.Assets[SlotIndex];
				if (Asset.VoiceLines.Num() < 1)
					continue;

				FVoxDevTimelineValue NewValue;
				NewValue.DebugTriggerId = Asset.DebugTriggerId;

				// Assume last VL is the one we care about the most
				const FVoxDebugVoiceLine& VL = Asset.VoiceLines.Last();
				NewValue.DisplayText = VL.CharacterName.ToString();
				NewValue.Color = VL.CharacterColor;

				NewValue.VoiceLineIndex = VL.Index;
				NewValue.TooltipText = f"{Asset.Name}\n{VL.Index}:{VL.AssetName}\n{VL.ActorName}";

				TimelineLane.Slots[SlotIndex].AddValue(CurrentFrame, GameTime, NewValue);
			}
		}
	}
#endif
};

namespace UHazeVoxRunner
{
	UHazeVoxRunner Get()
	{
		return Game::GetSingleton(UHazeVoxRunner);
	}
};
