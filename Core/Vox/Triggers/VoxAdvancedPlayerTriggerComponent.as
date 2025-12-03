
enum EVoxAdvancedPlayerTriggerType
{
	Immediate,	  // The trigger will fire immediately when the conditions are true
	TimeInTrigger // The trigger conditions must remain true for a specified ammount of time for the trigger to fire
}

enum EVoxAdvancedPlayerTriggerRepeat
{
	None,		 // The trigger will not repeat while active
	WhileActive, // The trigger will continuisly fire as long as the trigger contitions are true
}

enum EVoxPlayerAdvancedDistanceCheckMode
{
	None,
	BetweenPlayers,
	FirstInsideToActor,
	OtherPlayerToActor
}

enum EVoxPlayerAdvanceTriggerState
{
	Trigger,
	Delay
}

class UVoxAdvancedPlayerTriggerComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(EditAnywhere, Category = "HazeVox Assets")
	UHazeVoxAsset VoxAsset;

	// If set, this event will be used if Mio is triggering the bark
	UPROPERTY(EditAnywhere, Category = "HazeVox Assets")
	UHazeVoxAsset MioVoxAsset;

	// If set, this event will be used if Zoe is triggering the bark
	UPROPERTY(EditAnywhere, Category = "HazeVox Assets")
	UHazeVoxAsset ZoeVoxAsset;

	// This event will be used for Mio if the distance check fails
	UPROPERTY(EditAnywhere, Category = "HazeVox Assets")
	UHazeVoxAsset MioAltVoxAsset;

	// This event will be used for Zoe if the distance check fails
	UPROPERTY(EditAnywhere, Category = "HazeVox Assets")
	UHazeVoxAsset ZoeAltVoxAsset;

	// Actors to be used if the playing VoxAssets uses any character that is not Mio/Zoe. Mio and Zoe do not need to be added.
	UPROPERTY(EditAnywhere, Category = "HazeVox Assets", Meta = (DisplayAfter = "ZoeAltVoxAsset"))
	TArray<TSoftObjectPtr<AHazeActor>> Actors;

	// Time to wait before playing after the trigger contitions are met.
	UPROPERTY(EditAnywhere, Category = "HazeVox")
	float DelayBeforePlaying = 0.0;

	// Max number of times trigger will play, -1 for infinite
	UPROPERTY(EditAnywhere, Category = "HazeVox")
	int TriggerFireLimit = 1;

	UPROPERTY(EditAnywhere, Category = "HazeVox")
	EVoxAdvancedPlayerTriggerRepeat RepeatMode = EVoxAdvancedPlayerTriggerRepeat::None;

	// Time to wait between before repeating the trigger, while the trigger conditions remain true
	UPROPERTY(EditAnywhere, Category = "HazeVox", Meta = (EditCondition = "RepeatMode == EVoxAdvancedPlayerTriggerRepeat::WhileActive"))
	float TimeBetweenRepeats = 1.0;

	/** Max number of repeat attempts.
	 * -1 for infinite repeats.
	 * */
	UPROPERTY(EditAnywhere, Category = "HazeVox", Meta = (EditCondition = "RepeatMode == EVoxAdvancedPlayerTriggerRepeat::WhileActive"))
	int NumRepeats = -1;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "HazeVox")
	EVoxAdvancedPlayerTriggerType TriggerType = EVoxAdvancedPlayerTriggerType::Immediate;

	// Time the trigger conditions must remain valid before the trigger fires.
	UPROPERTY(EditAnywhere, Category = "HazeVox", Meta = (EditCondition = "TriggerType == EVoxAdvancedPlayerTriggerType::TimeInTrigger"))
	float TimeInTrigger = 1.0;

	// True if the internal timer should be reset if the trigger conditions stop being valid.
	UPROPERTY(EditAnywhere, Category = "HazeVox", Meta = (EditCondition = "TriggerType == EVoxAdvancedPlayerTriggerType::TimeInTrigger"))
	bool bResetTimeInTriggerOnLeave = true;

	// Distance is checked right before playing, after Time In Trigger and Delay Before Playing.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "HazeVox")
	EVoxPlayerAdvancedDistanceCheckMode DistanceCheckMode = EVoxPlayerAdvancedDistanceCheckMode::None;

	/**
	 * Distance that will be used for the distance check
	 * The check will pass if the distance between the actors are less than this.
	 */
	UPROPERTY(EditAnywhere, Category = "HazeVox", Meta = (EditCondition = "DistanceCheckMode != EVoxPlayerAdvancedDistanceCheckMode::None"))
	float DistanceLimit = 1000.0;

	// Actor placed in level to do the distance check against.
	UPROPERTY(EditAnywhere, Category = "HazeVox", Meta = (EditCondition = "DistanceCheckMode == EVoxPlayerAdvancedDistanceCheckMode::FirstInsideToActor || DistanceCheckMode == EVoxPlayerAdvancedDistanceCheckMode::OtherPlayerToActor"))
	TSoftObjectPtr<AHazeActor> DistanceActor;

	UPROPERTY(EditAnywhere, Category = "HazeVox")
	FPlayerTriggerEvent OnVoxAssetTriggered;

	private EVoxPlayerAdvanceTriggerState TriggerState = EVoxPlayerAdvanceTriggerState::Trigger;

	private bool bPlayCrumbed = false;
	private AHazePlayerCharacter TriggeredBy;

	private float TimeInTriggerTimer = 0.0;
	private float RepeatDelayTimer = 0.0;
	private int RepeatCount = 0;
	private float DelayBeforePlayingTimer = 0.0;
	private int TriggerFireCount = 0;

	private bool bActive = false;
	private bool bStopAfterDelay = false;

	void StartTrigger(AHazePlayerCharacter InTriggeredBy, bool bInPlayCrumbed)
	{
		if (bActive)
			return;

		if (TriggerFireLimit > 0 && TriggerFireCount >= TriggerFireLimit)
			return;

		bActive = true;
		bPlayCrumbed = bInPlayCrumbed;
		TriggeredBy = InTriggeredBy;
		if (TriggerType == EVoxAdvancedPlayerTriggerType::TimeInTrigger)
			TimeInTriggerTimer = TimeInTrigger;

		SetComponentTickEnabled(true);
	}

	void StopTrigger()
	{
		if (!bActive)
			return;

		if (TriggerState == EVoxPlayerAdvanceTriggerState::Delay)
		{
			bStopAfterDelay = true;
			return;
		}

		bActive = false;
		TriggeredBy = nullptr;

		if (bResetTimeInTriggerOnLeave)
			TimeInTriggerTimer = 0.0;

		if (VoxCVar::HazeVoxAutoResetTriggers.GetInt() != 0)
		{
			TimeInTriggerTimer = 0.0;
			RepeatCount = 0.0;
		}

		SetComponentTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		switch (TriggerState)
		{
			case EVoxPlayerAdvanceTriggerState::Delay:
				TickDelay(DeltaTime);
				break;
			case EVoxPlayerAdvanceTriggerState::Trigger:
				TickTrigger(DeltaTime);
				break;
		}

#if TEST
		DebugTemporalLog();
#endif
	}

	private void TickDelay(float DeltaTime)
	{
		if (DelayBeforePlayingTimer > 0.0)
		{
			DelayBeforePlayingTimer -= DeltaTime;
			if (DelayBeforePlayingTimer > 0.0)
				return;
		}

		TriggerVoxAsset();

		TriggerState = EVoxPlayerAdvanceTriggerState::Trigger;

		if (bStopAfterDelay)
		{
			bStopAfterDelay = false;
			StopTrigger();
			return;
		}

		const bool bShouldRepeat = UpdateShouldRepeat();
		if (bShouldRepeat)
			return;

		SetComponentTickEnabled(false);
	}

	private void TickTrigger(float DeltaTime)
	{
		if (TimeInTriggerTimer > 0.0)
		{
			TimeInTriggerTimer -= DeltaTime;
			if (TimeInTriggerTimer > 0.0)
				return;
		}

		if (RepeatDelayTimer > 0.0)
		{
			RepeatDelayTimer -= DeltaTime;
			if (RepeatDelayTimer > 0.0)
				return;
		}

		if (DelayBeforePlaying > 0.0)
		{
			DelayBeforePlayingTimer = DelayBeforePlaying;
			TriggerState = EVoxPlayerAdvanceTriggerState::Delay;
			return;
		}

		TriggerVoxAsset();

		const bool bShouldRepeat = UpdateShouldRepeat();
		if (bShouldRepeat)
			return;

		SetComponentTickEnabled(false);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbPlayVoxAsset(AHazePlayerCharacter InTriggeredBy, UHazeVoxAsset ToPlay)
	{
		TriggeredBy = InTriggeredBy;
		LocalPlayVoxAsset(ToPlay);
	}

	private bool UpdateShouldRepeat()
	{
		if (RepeatMode == EVoxAdvancedPlayerTriggerRepeat::WhileActive)
		{
			if (TriggerFireLimit > 0 && TriggerFireCount >= TriggerFireLimit)
				return false;

			RepeatCount++;
			if (NumRepeats < 0 || RepeatCount <= NumRepeats)
			{
				RepeatDelayTimer = TimeBetweenRepeats;
				return true;
			}
		}
		return false;
	}

	private void LocalPlayVoxAsset(UHazeVoxAsset ToPlay)
	{
		HazePlayVoxSoftActors(ToPlay, Actors);
		OnVoxAssetTriggered.Broadcast(TriggeredBy);
	}

	private UHazeVoxAsset GetDefaultVoxAssetToPlay() const
	{
		if (TriggeredBy.IsMio() && MioVoxAsset != nullptr)
			return MioVoxAsset;

		if (TriggeredBy.IsZoe() && ZoeVoxAsset != nullptr)
			return ZoeVoxAsset;

		// Don't fallback to default asset if we are using alt assets and have some char specific set for non-alt
		const bool bHasCharSpecificAssets = MioVoxAsset != nullptr || ZoeVoxAsset != nullptr;
		if (DistanceCheckMode != EVoxPlayerAdvancedDistanceCheckMode::None && bHasCharSpecificAssets)
			return nullptr;

		return VoxAsset;
	}

	private UHazeVoxAsset GetAltVoxAssetToPlay() const
	{
		if (TriggeredBy.IsMio() && MioAltVoxAsset != nullptr)
			return MioAltVoxAsset;

		if (TriggeredBy.IsZoe() && ZoeAltVoxAsset != nullptr)
			return ZoeAltVoxAsset;

		// Don't fall back on default if using alt assets
		return nullptr;
	}

	private UHazeVoxAsset GetVoxAssetToPlay() const
	{
		switch (DistanceCheckMode)
		{
			case EVoxPlayerAdvancedDistanceCheckMode::None:
				return GetDefaultVoxAssetToPlay();

			case EVoxPlayerAdvancedDistanceCheckMode::BetweenPlayers:
			{
				const float DistanceBetween = Game::DistanceBetweenPlayers;
				if (DistanceBetween > DistanceLimit)
					return GetAltVoxAssetToPlay();
				else
					return GetDefaultVoxAssetToPlay();
			}
			case EVoxPlayerAdvancedDistanceCheckMode::FirstInsideToActor:
			{
				if (!IsValid(DistanceActor.Get()))
					return GetDefaultVoxAssetToPlay();

				const float DistanceTo = TriggeredBy.GetDistanceTo(DistanceActor.Get());
				if (DistanceTo > DistanceLimit)
					return GetAltVoxAssetToPlay();
				else
					return GetDefaultVoxAssetToPlay();
			}
			case EVoxPlayerAdvancedDistanceCheckMode::OtherPlayerToActor:
			{
				if (!IsValid(DistanceActor.Get()))
					return GetDefaultVoxAssetToPlay();

				AHazePlayerCharacter OtherPlayer = TriggeredBy.OtherPlayer;
				const float DistanceTo = OtherPlayer.GetDistanceTo(DistanceActor.Get());
				if (DistanceTo > DistanceLimit)
					return GetAltVoxAssetToPlay();
				else
					return GetDefaultVoxAssetToPlay();
			}
		}
	}

	private void TriggerVoxAsset()
	{
		TriggerFireCount++;

		UHazeVoxAsset ToPlay = GetVoxAssetToPlay();
		// Nothing to play, skip playing :)
		if (ToPlay == nullptr)
			return;

		if (bPlayCrumbed)
		{
			CrumbPlayVoxAsset(TriggeredBy, ToPlay);
		}
		else
		{
			LocalPlayVoxAsset(ToPlay);
		}
	}

#if TEST
	private void DebugTemporalLog()
	{
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);

		switch (TriggerState)
		{
			case EVoxPlayerAdvanceTriggerState::Delay:
				TemporalLog.Status("Delay", FLinearColor::Teal);
				break;
			case EVoxPlayerAdvanceTriggerState::Trigger:
				TemporalLog.Status("Trigger", FLinearColor::Green);
				break;
		}

		TemporalLog.Value("bPlayCrumbed", bPlayCrumbed);
		TemporalLog.Value("TimeInTriggerTimer", TimeInTriggerTimer);
		TemporalLog.Value("RepeatCount", RepeatCount);
		TemporalLog.Value("DelayBeforePlayingTimer", DelayBeforePlayingTimer);
		TemporalLog.Value("TriggeredBy", TriggeredBy);
		TemporalLog.Value("bStopAfterDelay", bStopAfterDelay);
	}
#endif
}