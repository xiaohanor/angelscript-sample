class UVoxSharedRuntimeAsset
{
	UHazeVoxAsset VoxAsset = nullptr;

	TArray<UHazeVoxCharacterTemplate> NeededCharacters;

	// NextIndex not used for dialogues
	int NextIndex = 0;
	TArray<int> ShuffledIndices;

	bool bPlayedOnce = false;
	bool bAllPlayedOnce = false;

	bool bTickCooldown;
	float Cooldown = 0.0;

#if TEST
	FString TemporalLogPath;
#endif

	int ResumeCount = 0;

	FRandomStream RandStream;

	TArray<float> CalculatedLineWeights;

	void Init(UHazeVoxAsset InVoxAsset, int RandSeedSalt)
	{
		VoxAsset = InVoxAsset;
#if TEST
		TemporalLogPath = f"Vox/{VoxHelpers::BuildLaneDebugName(VoxAsset.Lane)}";
#endif

		const int NameHash = int(VoxAsset.Name.ToString().GetHash());
		const int RandSeed = NameHash ^ RandSeedSalt;
		RandStream.Initialize(RandSeed);

		for (auto& VL : VoxAsset.VoiceLines)
		{
			if (!devEnsure(VL.CharacterTemplate != nullptr, f"CharacterTemplate not set on VoiceLine in VoxAsset {VoxAsset.Name}"))
				continue;

			NeededCharacters.AddUnique(VL.CharacterTemplate);
		}

		if (VoxAsset.Type != EHazeVoxAssetType::Dialogue && VoxAsset.PlayMode == EHazeVoxShuffleMode::Random && VoxAsset.VoiceLines.Num() > 1)
		{
			for (auto& VL : VoxAsset.VoiceLines)
			{
				if (VL.LineWeight != 50)
				{
					CalculatedLineWeights.SetNum(VoxAsset.VoiceLines.Num());
					break;
				}
			}
		}

		SetupVoiceLineOrder();
	}

	void TickCooldown(float DeltaTime)
	{
		Cooldown -= DeltaTime;
		if (Cooldown <= 0.0)
		{
			bTickCooldown = false;
		}
	}

	void AutoTickCooldown()
	{
		if (Cooldown > 0.0)
		{
			bTickCooldown = true;
		}
	}

	void ResetCooldown()
	{
		Cooldown = VoxAsset.Cooldown;
	}

	bool CanTrigger() const
	{
		if (VoxAsset.PlayOnce && bPlayedOnce && VoxCVar::HazeVoxDisablePlayOnce.GetInt() == 0)
		{
#if TEST
			VoxDebug::TemporalLogEvent(TemporalLogPath, f"{VoxAsset.Name} can't trigger from PlayOnce");
#endif
			return false;
		}

		if (VoxAsset.PlayAllOnce && bAllPlayedOnce && VoxCVar::HazeVoxDisablePlayOnce.GetInt() == 0)
		{
#if TEST
			VoxDebug::TemporalLogEvent(TemporalLogPath, f"{VoxAsset.Name} can't trigger from PlayAllOnce");
#endif
			return false;
		}

		if (Cooldown > 0.0 && VoxCVar::HazeVoxDisableCooldown.GetInt() == 0)
		{
#if TEST
			VoxDebug::TemporalLogEvent(TemporalLogPath, f"{VoxAsset.Name} can't trigger from Cooldown, {Cooldown}");
#endif
			return false;
		}

		return true;
	}

	int PreviewNextStartIndex() const
	{
		if (VoxAsset.Type == EHazeVoxAssetType::Dialogue)
			return 0;

		if (VoxAsset.VoiceLines.Num() == 1)
			return 0;

		if (VoxAsset.PlayMode == EHazeVoxShuffleMode::Shuffle)
			return ShuffledIndices[NextIndex];

		return NextIndex;
	}

	int GetNextIndex()
	{
		// Always do 0 for dialogues
		if (VoxAsset.Type == EHazeVoxAssetType::Dialogue)
			return 0;

		// Always do ordered when <= 2 voice lines
		if (VoxAsset.VoiceLines.Num() <= 2)
			return GetNextIndexOrdered();

		// Always do ordered for Dialogues
		if (VoxAsset.Type == EHazeVoxAssetType::Dialogue)
			GetNextIndexOrdered();

		switch (VoxAsset.PlayMode)
		{
			case EHazeVoxShuffleMode::Shuffle:
			{
				int ShuffledIndex = ShuffledIndices[NextIndex];
				NextIndex++;
				if (NextIndex >= ShuffledIndices.Num())
				{
					ShuffleShuffledIndices();
					bAllPlayedOnce = true;
				}
				return ShuffledIndex;
			}
			case EHazeVoxShuffleMode::Random:
			{
				int Index = NextIndex;
				if (CalculatedLineWeights.IsEmpty())
				{
					NextIndex = RandStream.RandRange(0, VoxAsset.VoiceLines.Num() - 2);
					if (NextIndex >= Index)
						NextIndex++;
				}
				else
				{
					CalculateWeights(Index);
					NextIndex = NextWeightedRandomIndex();
				}
				return Index;
			}
			case EHazeVoxShuffleMode::Ordered:
			{
				return GetNextIndexOrdered();
			}
		}
	}

	int GetNextDialogueIndex(int VoiceLineIndex) const
	{
		return (VoiceLineIndex + 1) % VoxAsset.VoiceLines.Num();
	}

	void UpdateDialogueAllPlayed(int VoiceLineIndex)
	{
		if (VoiceLineIndex == VoxAsset.VoiceLines.Num() - 1)
			bAllPlayedOnce = true;
	}

	void IncrementResumeCount()
	{
		ResumeCount++;
	}

	private void SetupVoiceLineOrder()
	{
		if (VoxAsset.VoiceLines.Num() == 1)
		{
			NextIndex = 0;
			return;
		}

		// Always do ordered for dialogues
		if (VoxAsset.Type == EHazeVoxAssetType::Dialogue)
			NextIndex = 0;

		switch (VoxAsset.PlayMode)
		{
			case EHazeVoxShuffleMode::Shuffle:
				ShuffledIndices.Empty(VoxAsset.VoiceLines.Num());
				for (int i = 0; i < VoxAsset.VoiceLines.Num(); ++i)
				{
					ShuffledIndices.Add(i);
				}
				VoxHelpers::ShuffleIndexArray(ShuffledIndices, RandStream);

				NextIndex = 0;
				break;

			case EHazeVoxShuffleMode::Random:
				if (CalculatedLineWeights.IsEmpty())
				{
					NextIndex = RandStream.RandRange(0, VoxAsset.VoiceLines.Num() - 1);
				}
				else
				{
					CalculateWeights(-1);
					NextIndex = NextWeightedRandomIndex();
				}

				break;

			case EHazeVoxShuffleMode::Ordered:
				NextIndex = 0;
				break;
		}
	}

	private void ShuffleShuffledIndices()
	{
		int BannedStartIndex = ShuffledIndices.Last();
		VoxHelpers::ShuffleIndexArray(ShuffledIndices, RandStream);
		if (ShuffledIndices[0] == BannedStartIndex)
		{
			ShuffledIndices.Swap(0, RandStream.RandRange(1, ShuffledIndices.Num() - 1));
		}
		NextIndex = 0;
	}

	private int GetNextIndexOrdered()
	{
		int Index = NextIndex;
		NextIndex = (NextIndex + 1) % VoxAsset.VoiceLines.Num();
		if (NextIndex == 0)
		{
			bAllPlayedOnce = true;
		}
		return Index;
	}

	// BannedIndex < 0 if no banned index
	private void CalculateWeights(int32 BannedIndex)
	{
		float TotalWeights = 0;
		for (int i = 0; i < CalculatedLineWeights.Num(); ++i)
		{
			if (i == BannedIndex)
				continue;
			TotalWeights += VoxAsset.VoiceLines[i].LineWeight;
		}

		float SummedWeights = 0.0;
		for (int i = 0; i < CalculatedLineWeights.Num(); ++i)
		{
			if (i == BannedIndex)
			{
				// Lines with weight < 0 are ignored
				CalculatedLineWeights[i] = -1.0;
				continue;
			}

			float ProportionalWeight = VoxAsset.VoiceLines[i].LineWeight / TotalWeights;
			SummedWeights += ProportionalWeight;
			CalculatedLineWeights[i] = SummedWeights;
		}
	}

	private int32 NextWeightedRandomIndex()
	{
		const float Rand = RandStream.GetFraction();
		for (int i = 0; i < CalculatedLineWeights.Num(); ++i)
		{
			if (CalculatedLineWeights[i] < SMALL_NUMBER)
				continue;

			if (CalculatedLineWeights[i] >= Rand)
				return i;
		}

		// return last line as fallback for rare case where final sum < 1.0 and rand == 1.0;
		return CalculatedLineWeights.Num() - 1;
	}
}