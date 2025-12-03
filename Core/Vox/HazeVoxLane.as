

enum EVoxLaneSlotSortType
{
	Priority,
	PriorityAge,
	Age,
}

struct FVoxLaneQueueItem
{
	UVoxRuntimeAsset RuntimeAsset;
}

class UVoxLane
{
	const EHazeVoxLaneName LaneName;
#if TEST
	const FString TemporalLogPrefix;
	const FString TemporalLogPath;
#endif
	const int NumSlots;
	const EVoxLaneSlotSortType SlotType;

	private TArray<UVoxRuntimeAsset> RuntimeSlots;
	private TArray<UVoxRuntimeAsset> TailingOutAssets;
	private TArray<FVoxLaneQueueItem> QueuedAssets;

	UVoxLane(EHazeVoxLaneName InLaneName, int InNumSlots, EVoxLaneSlotSortType InSlotType = EVoxLaneSlotSortType::Priority)
	{
		NumSlots = InNumSlots;
		SlotType = InSlotType;
		LaneName = InLaneName;
#if TEST
		TemporalLogPrefix = VoxHelpers::BuildLaneDebugName(LaneName);
		TemporalLogPath = f"Vox/{TemporalLogPrefix}";
#endif
	}

	void Tick(float DeltaTime)
	{
		for (int i = TailingOutAssets.Num() - 1; i >= 0; --i)
		{
			TailingOutAssets[i].Tick(DeltaTime);
			if (TailingOutAssets[i].IsStopped())
			{
				TailingOutAssets.RemoveAtSwap(i);
			}
		}

		for (int i = QueuedAssets.Num() - 1; i >= 0; --i)
		{
			bool bKeepQueued = QueuedAssets[i].RuntimeAsset.TickQueue(DeltaTime);
			if (!bKeepQueued)
			{
				QueuedAssets.RemoveAt(i);
			}
		}

		for (int i = RuntimeSlots.Num() - 1; i >= 0; --i)
		{
			RuntimeSlots[i].Tick(DeltaTime);
			if (RuntimeSlots[i].IsStopped())
			{
				RuntimeSlots.RemoveAt(i);
			}
			else if (RuntimeSlots[i].IsTailingOut())
			{
				TailingOutAssets.Add(RuntimeSlots[i]);
				RuntimeSlots.RemoveAt(i);
			}
		}
	}

	void Play(UVoxRuntimeAsset RuntimeAsset, int VoiceLineIndex, bool bFromQueue)
	{
		TArray<AHazeActor> TemplateActors;
		RuntimeAsset.GetTemplateActors(TemplateActors);
		StopIfBlocked(TemplateActors);

		// Remove from slots until we can fit this one
		int ToRemove = Math::Max(0, RuntimeSlots.Num() - (NumSlots - 1));
		for (int i = 0; i < ToRemove; ++i)
		{
			int LastIndex = RuntimeSlots.Num() - 1;
			RuntimeSlots[LastIndex].Stop();
			RuntimeSlots.RemoveAt(LastIndex);
		}

		int InsertIndex = FindInsertIndex(RuntimeAsset);
		if (InsertIndex < 0)
		{
			devError(f"Bad InsertIndex {InsertIndex} when playing {RuntimeAsset.GetVoxAsset().Name} on lane {LaneName");
			return;
		}

		RuntimeSlots.Insert(RuntimeAsset, InsertIndex);
		RuntimeSlots[InsertIndex].Play(VoiceLineIndex, bFromQueue);
	}

	void ResetLane()
	{
		for (auto Asset : RuntimeSlots)
		{
			Asset.Stop(false);
		}
		RuntimeSlots.Reset();

		for (auto Asset : TailingOutAssets)
		{
			Asset.Stop(false);
		}
		TailingOutAssets.Reset();

		for (FVoxLaneQueueItem& QueueItem : QueuedAssets)
		{
			QueueItem.RuntimeAsset.Stop(false);
		}
		QueuedAssets.Reset();
	}

	void StopIfBlocked(const TArray<AHazeActor>& BlockingActors)
	{
		for (int i = RuntimeSlots.Num() - 1; i >= 0; --i)
		{
			if (RuntimeSlots[i].IsBlockingActors(BlockingActors, false))
			{
				RuntimeSlots[i].Stop();
				RuntimeSlots.RemoveAt(i);
			}
		}
	}

	bool PauseUsingActor(AHazeActor Actor)
	{
		for (int i = RuntimeSlots.Num() - 1; i >= 0; --i)
		{
			if (RuntimeSlots[i].IsActorActive(Actor, true))
			{
				// Pretend we are paused since we hit the right actor
				if (RuntimeSlots[i].VoxAsset.bPlayDuringPaused)
					return true;

				RuntimeSlots[i].Pause(Actor);
				return true;
			}
		}
		return false;
	}

	bool ResumeUsingActor(AHazeActor Actor)
	{
		for (int i = RuntimeSlots.Num() - 1; i >= 0; --i)
		{
			if (RuntimeSlots[i].IsActorActive(Actor, true))
			{
				RuntimeSlots[i].Resume(Actor);
				return true;
			}
		}
		return false;
	}

	void QueueAsset(FVoxLaneQueueItem QueueItem)
	{
		// Insert sorted
		int InsertIndex = 0;
		for (int QueueIndex = 0; QueueIndex < QueuedAssets.Num(); ++QueueIndex)
		{
			// If same prio put new one in front
			if (QueuedAssets[QueueIndex].RuntimeAsset.GetVoxAsset().Priority <= QueueItem.RuntimeAsset.GetVoxAsset().Priority)
			{
				break;
			}
			InsertIndex++;
		}
		QueuedAssets.Insert(QueueItem, InsertIndex);
		QueueItem.RuntimeAsset.PlacedInQueue();
	}

	bool GetNextInQueue(FVoxLaneQueueItem&out OutQueueItem)
	{
		if (QueuedAssets.Num() <= 0)
			return false;

		TArray<AHazeActor> MatchingActors;
		EVoxControllerCanTriggerResult CanTriggerResult = UHazeVoxController::Get().MatchActorsAndCheckCanTrigger(QueuedAssets[0].RuntimeAsset.SharedAsset, QueuedAssets[0].RuntimeAsset.TemplateActors, EHazeVoxLaneInterruptType::None, MatchingActors);

		if (CanTriggerResult == EVoxControllerCanTriggerResult::CanTrigger)
		{
			OutQueueItem = QueuedAssets[0];
			QueuedAssets.RemoveAt(0);
		}
		else
		{
			if (CanTriggerResult == EVoxControllerCanTriggerResult::FullyBlocked)
			{
				// Remove from queueu, assume someting is borked
				QueuedAssets[0].RuntimeAsset.TriggerInterruptedDelegates();
				QueuedAssets.RemoveAt(0);
			}
			return false;
		}

		// Update actors or add ensure that the lists are the same?
		OutQueueItem.RuntimeAsset.TemplateActors = MatchingActors;

		return true;
	}

	void ToggleHardPause(bool bPaused)
	{
		if (bPaused)
		{
			for (UVoxRuntimeAsset Asset : RuntimeSlots)
			{
				Asset.HardPause();
			}
			for (UVoxRuntimeAsset Asset : TailingOutAssets)
			{
				Asset.HardPause();
			}
		}
		else
		{
			for (UVoxRuntimeAsset Asset : RuntimeSlots)
			{
				Asset.HardResume();
			}
			for (UVoxRuntimeAsset Asset : TailingOutAssets)
			{
				Asset.HardResume();
			}
		}
	}

	bool IsPlaying()
	{
		return RuntimeSlots.Num() > 0;
	}

	bool IsBlockingActor(AHazeActor Actor) const
	{
		TArray<AHazeActor> Actors;
		Actors.Add(Actor);
		for (auto Asset : RuntimeSlots)
		{
			if (Asset.IsBlockingActors(Actors, false))
			{
				return true;
			}
		}
		return false;
	}

	void StopAsset(UHazeVoxAsset VoxAsset)
	{
		for (int i = RuntimeSlots.Num() - 1; i >= 0; --i)
		{
			if (RuntimeSlots[i].VoxAsset.Name == VoxAsset.Name)
			{
#if TEST
				VoxDebug::TemporalLogEvent(RuntimeSlots[i].SharedAsset.TemporalLogPath, f"Interrupting VoxAsset {VoxAsset.Name}");
#endif

				RuntimeSlots[i].Stop();
				RuntimeSlots.RemoveAt(i);
			}
		}
	}

	bool TestPriority(UVoxSharedRuntimeAsset TestAsset, TArray<AHazeActor> MatchingActors)
	{
		switch (SlotType)
		{
			case EVoxLaneSlotSortType::Priority:
			{
				for (auto Asset : RuntimeSlots)
				{
					if (Asset.GetVoxAsset().Priority < TestAsset.VoxAsset.Priority)
					{
						return true;
					}
					else if (Asset.IsBlockingActors(MatchingActors, false))
					{
						// Blocket by higher prio
						return false;
					}
				}

				if (RuntimeSlots.Num() < NumSlots)
				{
					return true;
				}

				return false;
			}
			case EVoxLaneSlotSortType::PriorityAge:
			{
				bool bEqualChecked = false;
				for (auto Asset : RuntimeSlots)
				{
					if (Asset.GetVoxAsset().Priority < TestAsset.VoxAsset.Priority)
					{
						// We can play if something has lower prio
						return true;
					}
					else if (Asset.IsBlockingActors(MatchingActors, false))
					{
						// If any with higher or equal prio blocks then dont play
						return false;
					}

					if (Asset.GetVoxAsset().Priority == TestAsset.VoxAsset.Priority)
					{
						bEqualChecked = true;
					}
				}

				// If we checked for equal and wasnt blocked then we can trigger
				if (bEqualChecked == true)
				{
					return true;
				}

				// If there are free slots we can trigger
				if (RuntimeSlots.Num() < NumSlots)
				{
					return true;
				}

				// If we are lower prio and there are no free slots then don't play
				return false;
			}
			case EVoxLaneSlotSortType::Age:
			{
				// Can always play when sorting by age
				return true;
			}
		}
	}

	bool CanAssetQueue(UVoxSharedRuntimeAsset SharedAsset)
	{
		// If we have a matching asset check if it can queue
		for (UVoxRuntimeAsset RuntimeAsset : TailingOutAssets)
		{
			if (RuntimeAsset.SharedAsset == SharedAsset)
			{
				return RuntimeAsset.CanQueue();
			}
		}

		for (UVoxRuntimeAsset RuntimeAsset : RuntimeSlots)
		{
			if (RuntimeAsset.SharedAsset == SharedAsset)
			{
				return RuntimeAsset.CanQueue();
			}
		}

		// Otherwise we can queue since its not running
		return true;
	}

	void GetActiveActors(TArray<AHazeActor>& OutActiveActors, bool bPausedAsActive)
	{
		for (auto Asset : RuntimeSlots)
		{
			Asset.GetActiveActors(OutActiveActors, bPausedAsActive);
		}
	}
#if TEST
	FVoxDebugLane BuildDebugInfo()
	{
		FVoxDebugLane DebugLane;
		DebugLane.LaneName = LaneName;

		for (auto Asset : RuntimeSlots)
		{
			DebugLane.Assets.Add(Asset.BuildDebugInfo());
		}

		for (auto Asset : TailingOutAssets)
		{
			DebugLane.TailingOutAssets.Add(Asset.BuildDebugInfo());
		}

		return DebugLane;
	}

	void DebugTemporalLog(FTemporalLog& TemporalLog) const
	{
		FTemporalLog GroupLog = TemporalLog.Page(TemporalLogPrefix);
		if (RuntimeSlots.Num() <= 0)
		{
			if (TailingOutAssets.Num() > 0)
			{
				GroupLog.Status("TailingOut", FLinearColor::Teal);
			}
			else
			{
				GroupLog.Status("Idle", FLinearColor::White);
			}
		}
		else
		{
			GroupLog.Status("Playing", FLinearColor::Green);
		}

		GroupLog.Value("Slots", f"{RuntimeSlots.Num()}/{NumSlots}");
		GroupLog.Value("TailingOutAssets", TailingOutAssets.Num());
		GroupLog.Value("ResumeInfos", TailingOutAssets.Num());

		for (int i = 0; i < RuntimeSlots.Num(); ++i)
		{
			FString Prefix = f"Slot_{i}";
			RuntimeSlots[i].DebugTemporalLog(GroupLog, Prefix);
		}

		for (int i = 0; i < TailingOutAssets.Num(); ++i)
		{
			FString Prefix = f"TailingOutAsset_{i}";
			TailingOutAssets[i].DebugTemporalLog(GroupLog, Prefix);
		}

		for (int i = 0; i < QueuedAssets.Num(); ++i)
		{
			FString Prefix = f"QueuedAsset_{i}";
			QueuedAssets[i].RuntimeAsset.DebugTemporalLogQueue(GroupLog, Prefix);
		}
	}

	void DebugTemporalLogSummary(FTemporalLog& TemporalLog) const
	{
		const FString PrefixedPrefix = f"{int(LaneName)}_{TemporalLogPrefix}";
		if (RuntimeSlots.Num() <= 0)
		{
			if (TailingOutAssets.Num() > 0)
			{
				TemporalLog.CustomStatus(f"{PrefixedPrefix};Status", "TailingOut", FLinearColor::Teal);
			}
			else
			{
				TemporalLog.CustomStatus(f"{PrefixedPrefix};Status", "Idle", FLinearColor::White);
			}
		}
		else
		{
			TemporalLog.CustomStatus(f"{PrefixedPrefix};Status", "Playing", FLinearColor::Green);
		}

		for (int i = 0; i < RuntimeSlots.Num(); ++i)
		{
			FString Prefix = f"{PrefixedPrefix};Slot_{i}";
			RuntimeSlots[i].DebugTemporalLogSummary(TemporalLog, Prefix);
		}
	}
#endif

	private int FindInsertIndex(UVoxRuntimeAsset RuntimeAsset) const
	{
		switch (SlotType)
		{
			case EVoxLaneSlotSortType::Priority:
			{
				if (RuntimeSlots.Num() <= 0)
				{
					return 0;
				}

				for (int i = 0; i < RuntimeSlots.Num(); ++i)
				{
					if (RuntimeSlots[i].GetVoxAsset().Priority < RuntimeAsset.GetVoxAsset().Priority)
					{
						return i;
					}
				}

				return RuntimeSlots.Num() - 1;
			}
			case EVoxLaneSlotSortType::PriorityAge:
			{
				if (RuntimeSlots.Num() <= 0)
				{
					return 0;
				}

				for (int i = 0; i < RuntimeSlots.Num(); ++i)
				{
					// Insert at the first asset with same priority
					if (RuntimeSlots[i].GetVoxAsset().Priority <= RuntimeAsset.GetVoxAsset().Priority)
					{
						return i;
					}
				}

				return RuntimeSlots.Num() - 1;
			}
			case EVoxLaneSlotSortType::Age:
			{
				// Allways insert first when sorting by age
				return 0;
			}
		}
	}
};
