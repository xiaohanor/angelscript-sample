
enum EVoxDuoPlayerChanceType
{
	AlwaysBoth,
	IndividualRoll,
	RollBetween
}

class UVoxDuoPlayerTriggerComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	// If set, this event will be used if Mio is triggering the bark
	UPROPERTY(EditAnywhere, Category = "HazeVox Assets")
	UHazeVoxAsset MioVoxAsset;

	// If set, this event will be used if Zoe is triggering the bark
	UPROPERTY(EditAnywhere, Category = "HazeVox Assets")
	UHazeVoxAsset ZoeVoxAsset;

	// Actors to be used if the playing VoxAssets uses any character that is not Mio/Zoe. Mio and Zoe do not need to be added.
	UPROPERTY(EditAnywhere, Category = "HazeVox Assets", Meta = (DisplayAfter = "ZoeAltVoxAsset"))
	TArray<TSoftObjectPtr<AHazeActor>> Actors;

	// Time to wait before playing after the trigger contitions are met.
	UPROPERTY(EditAnywhere, Category = "HazeVox")
	float DelayBeforePlaying = 0.0;

	UPROPERTY(EditAnywhere, Category = "HazeVox")
	EVoxDuoPlayerChanceType ChanceType = EVoxDuoPlayerChanceType::AlwaysBoth;

	UPROPERTY(EditAnywhere, Category = "HazeVox", Meta = (ClampMin = "1", ClampMax = "100", EditCondition = "ChanceType == EVoxDuoPlayerChanceType::IndividualRoll"))
	int MioChance = 100;

	UPROPERTY(EditAnywhere, Category = "HazeVox", Meta = (ClampMin = "1", ClampMax = "100", EditCondition = "ChanceType == EVoxDuoPlayerChanceType::IndividualRoll"))
	int ZoeChance = 100;

	UPROPERTY(EditAnywhere, Category = "HazeVox", Meta = (EditCondition = "ChanceType == EVoxDuoPlayerChanceType::IndividualRoll"))
	bool bChanceForcePlay = true;

	UPROPERTY(EditAnywhere, Category = "HazeVox", Meta = (ClampMin = "1", ClampMax = "99", EditCondition = "ChanceType == EVoxDuoPlayerChanceType::RollBetween"))
	int MioVsZoeChance = 50;

	private bool bPlayCrumbed = false;
	private float DelayBeforePlayingTimer = 0.0;
	private bool bActive = false;
	private bool bHasPlayed = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		TickDelay(DeltaTime);
#if TEST
		DebugTemporalLog();
#endif
	}

	private void TickDelay(float DeltaTime)
	{
		if (DelayBeforePlayingTimer > 0.0)
		{
			DelayBeforePlayingTimer -= DeltaTime;
			if (DelayBeforePlaying > 0.0)
				return;
		}

		TriggerVoxAsset();
		SetComponentTickEnabled(false);
	}

	void StartTrigger(bool bInPlayCrumbed)
	{
		if (bHasPlayed)
			return;

		if (bActive)
			return;

		bActive = true;
		bPlayCrumbed = bInPlayCrumbed;

		if (DelayBeforePlaying > 0.0)
		{
			DelayBeforePlayingTimer = DelayBeforePlaying;
			SetComponentTickEnabled(true);
		}
		else
		{
			TriggerVoxAsset();
		}
	}

	void StopTrigger()
	{
		// There is nothing to stop this in trigger since it has no advanced conditions
	}

	UFUNCTION(CrumbFunction)
	private void CrumbPlayVoxAsset(UHazeVoxAsset ToPlayMio, UHazeVoxAsset ToPlayZoe)
	{
		LocalPlayVoxAsset(ToPlayMio, ToPlayZoe);
	}

	private void LocalPlayVoxAsset(UHazeVoxAsset ToPlayMio, UHazeVoxAsset ToPlayZoe)
	{
		bHasPlayed = true;
		if (ToPlayMio != nullptr)
			HazePlayVoxSoftActors(ToPlayMio, Actors);

		if (ToPlayZoe != nullptr)
			HazePlayVoxSoftActors(ToPlayZoe, Actors);
	}

	private void IndividualRoll(UHazeVoxAsset&out ToPlayMio, UHazeVoxAsset&out ToPlayZoe)
	{
		int MioRoll = 100;
		int ZoeRoll = 100;

		if (MioChance == 100)
		{
			ToPlayMio = MioVoxAsset;
		}
		else
		{
			MioRoll = Math::RandRange(1, 100);
			if (MioRoll <= MioChance)
			{
				ToPlayMio = MioVoxAsset;
			}
			else
			{
				ToPlayMio = nullptr;
			}
		}

		if (ZoeChance == 100)
		{
			ToPlayZoe = ZoeVoxAsset;
		}
		else
		{
			ZoeRoll = Math::RandRange(1, 100);
			if (ZoeRoll <= ZoeChance)
			{
				ToPlayZoe = ZoeVoxAsset;
			}
			else
			{
				ToPlayZoe = nullptr;
			}
		}

#if TEST
		TEMPORAL_LOG(this).Event(f"Rolled Mio: {MioRoll}/{MioChance} Zoe: {ZoeRoll}/{ZoeChance}");
#endif

		const bool bHasAsset = ToPlayMio != nullptr || ToPlayZoe != nullptr;
		if (bChanceForcePlay && !bHasAsset)
		{
			// If there is less than both, use assets
			if (MioVoxAsset == nullptr || ZoeVoxAsset == nullptr)
			{
				ToPlayMio = MioVoxAsset;
				ToPlayZoe = ZoeVoxAsset;
				return;
			}

			if (MioRoll == ZoeRoll)
			{
				// Little bit uncecessary scenario, doing it for the lulz
				const bool bPlayMio = Math::RandBool();
				if (bPlayMio)
				{
					ToPlayMio = MioVoxAsset;
					ToPlayZoe = nullptr;
				}
				else
				{
					ToPlayMio = nullptr;
					ToPlayZoe = ZoeVoxAsset;
				}

#if TEST
				TEMPORAL_LOG(this).Event(f"Tiebreaker Mio: {bPlayMio}");
#endif
			}
			else if (MioRoll > ZoeRoll)
			{
				ToPlayMio = MioVoxAsset;
				ToPlayZoe = nullptr;
			}
			else
			{
				ToPlayMio = nullptr;
				ToPlayZoe = ZoeVoxAsset;
			}
		}
	}

	private void ChanceBetween(UHazeVoxAsset&out ToPlay)
	{
		// Early out if we don't have two assets
		if (MioVoxAsset == nullptr)
		{
			ToPlay = ZoeVoxAsset;
			return;
		}
		else if (ZoeVoxAsset == nullptr)
		{
			ToPlay = MioVoxAsset;
			return;
		}

		const int Roll = Math::RandRange(1, 100);
		if (Roll <= MioVsZoeChance)
		{
			ToPlay = MioVoxAsset;
		}
		else
		{
			ToPlay = ZoeVoxAsset;
		}

#if TEST
		TEMPORAL_LOG(this).Event(f"Rolled Versus: {Roll}/{MioVsZoeChance}");
#endif
	}

	private void TriggerVoxAsset()
	{
		// Early out if no assets assigned
		if (MioVoxAsset == nullptr && ZoeVoxAsset == nullptr)
		{
			bHasPlayed = true;
			return;
		}

		UHazeVoxAsset ToPlayMio = nullptr;
		UHazeVoxAsset ToPlayZoe = nullptr;
		switch (ChanceType)
		{
			case EVoxDuoPlayerChanceType::AlwaysBoth:
				ToPlayMio = MioVoxAsset;
				ToPlayZoe = ZoeVoxAsset;
				break;

			case EVoxDuoPlayerChanceType::IndividualRoll:
				IndividualRoll(ToPlayMio, ToPlayZoe);
				break;

			case EVoxDuoPlayerChanceType::RollBetween:
				// Use "Mio" as default asset when we only have one
				ChanceBetween(ToPlayMio);
				break;
		}

		if (ToPlayMio == nullptr && ToPlayZoe == nullptr)
		{
			// Nothing to play
			bHasPlayed = true;
			return;
		}

		if (bPlayCrumbed)
		{
			CrumbPlayVoxAsset(ToPlayMio, ToPlayZoe);
		}
		else
		{
			LocalPlayVoxAsset(ToPlayMio, ToPlayZoe);
		}
	}

#if TEST
	private void DebugTemporalLog()
	{
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);

		TemporalLog.Status("Active", FLinearColor::Green);

		TemporalLog.Value("bPlayCrumbed", bPlayCrumbed);
		TemporalLog.Value("DelayBeforePlayingTimer", DelayBeforePlayingTimer);
		TemporalLog.Value("bActive", bActive);
		TemporalLog.Value("bHasPlayed", bHasPlayed);
	}
#endif
};