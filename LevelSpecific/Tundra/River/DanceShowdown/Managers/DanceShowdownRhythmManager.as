struct FDanceShowdownOnMeasureEventData
{
	int Measure = 0;
	bool bIsRestMeasure = true;
}

struct FDanceShowdownOnBeatEventData
{
	int Beat;
	int Measure;
	bool bIsRestMeasure;

	bool IsFirstBeat() const
	{
		return Beat == 1;
	}

	bool IsFirstMeasure() const
	{
		return Measure == 0;
	}
}

struct FDanceShowdownOnNewStageEventData
{
	int Stage;
}


event void FDanceShowdownOnMeasureEvent(FDanceShowdownOnMeasureEventData Data);
event void FDanceShowdownOnBeatEvent(FDanceShowdownOnBeatEventData Data);
event void FDanceShowdownOnNewStageEvent(FDanceShowdownOnNewStageEventData Data);
event void FDanceShowdownOnGameResumeEvent();
event void FDanceShowdownOnLoseEvent();

class UDanceShowdownRhythmManager : UActorComponent
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY()
	FDanceShowdownOnBeatEvent OnBeatEvent;
	
	UPROPERTY()
	FDanceShowdownOnMeasureEvent OnMeasureEvent;
	FDanceShowdownOnMeasureEventData CurrentMeasureData;

	UPROPERTY()
	FDanceShowdownOnNewStageEvent OnNewStageEvent;

	FDanceShowdownOnGameResumeEvent OnGameResumeEvent;

	private bool bIsActive = false;
	private float ActivateTime = 0;
	private bool bIsPaused = false;
	private int BeatCounter = 0;
	private int RestMeasureBeatLength = DanceShowdown::RestBeatDurationStageOne;

	private int CurrentStage = 0;
	private int StageToSet = 0;

	private float TimeSinceLastBeat = 0;

	int IdleAnimationIndex = 0;

	UFUNCTION()
	void IncrementIdleAnimationIndex()
	{
		IdleAnimationIndex++;
		if(IdleAnimationIndex >= 4)
			IdleAnimationIndex = 0;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActivateTime = Time::GameTimeSeconds;
		DanceShowdown::GetManager().FaceMonkeyManager.OnBothMonkeysRemovedEvent.AddUFunction(this, n"Unpause");
		DanceShowdown::GetManager().ScoreManager.OnPerfectMeasure.AddUFunction(this, n"IncrementIdleAnimationIndex");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!HasControl())
			return;
		
		#if !RELEASE
			TEMPORAL_LOG(this)
			.Value("bIsActive", bIsActive)
			.Value("ActivateTime", ActivateTime)
			.Value("bIsPaused", bIsPaused)
			.Value("BeatCounter", BeatCounter)
			.Value("CurrentStage", CurrentStage)
			.Value("StageToSet", StageToSet)
			.Value("TimeSinceLastBeat", TimeSinceLastBeat)
			;
		#endif

		if(!bIsActive)
			return;

		TimeSinceLastBeat += DeltaSeconds;

		PrintToScreen("Beat: " + BeatCounter);

		if(TimeSinceLastBeat > GetRealTimeBetweenBeats())
		{
			BeatCounter += Math::FloorToInt(TimeSinceLastBeat / GetRealTimeBetweenBeats());
			float Remainder = TimeSinceLastBeat % GetRealTimeBetweenBeats();
			TimeSinceLastBeat = Remainder;
			NetNewBeat(BeatCounter);
		}
	}

	UFUNCTION(NetFunction)
	void NetNewBeat(int NewBeatCount)
	{
		BeatCounter = NewBeatCount;
		
		if(bIsPaused)
			return;
		
		if(IsMeasureDone())
		{
			BeatCounter = 1;
			CurrentMeasureData.Measure++;
			OnMeasureEvent.Broadcast(CurrentMeasureData);
			CurrentMeasureData.bIsRestMeasure = !CurrentMeasureData.bIsRestMeasure;
		}

		FDanceShowdownOnBeatEventData EventData;
		EventData.bIsRestMeasure = CurrentMeasureData.bIsRestMeasure;
		EventData.Beat = BeatCounter;
		EventData.Measure = CurrentMeasureData.Measure;
		TEMPORAL_LOG(this)
		.Event("new beat");
		OnBeatEvent.Broadcast(EventData);
	}

	UFUNCTION(BlueprintCallable)
	void UpdateStage()
	{
		IdleAnimationIndex = 0;
		CurrentStage = StageToSet;
		DanceShowdown::GetManager().ScoreManager.ResetScore();

		if(CurrentStage == 1)
			RestMeasureBeatLength = DanceShowdown::RestBeatDurationStageTwo;
		else
			RestMeasureBeatLength = DanceShowdown::RestBeatDurationStageThree;
	}

	void CancelMeasure()
	{
		BeatCounter = 1;

		CurrentMeasureData.bIsRestMeasure = true;
		OnMeasureEvent.Broadcast(CurrentMeasureData);
	}

	int GetCurrentStage()
	{
		return CurrentStage;
	}


	void StopDanceShowdown()
	{
		DanceShowdown::GetManager().StopDanceShowdown();
	}

	bool IsPaused() const
	{
		return bIsPaused;
	}

	UFUNCTION(NetFunction)
	void NetIncreaseStage()
	{
		StageToSet++;
		SetNewStage(StageToSet);
	}

	private void SetNewStage(int NewStage)
	{
		Pause();

		StageToSet = NewStage;
		if(StageToSet == DanceShowdown::AmountOfStages)
		{
			StopDanceShowdown();
			return;
		}

		FDanceShowdownOnNewStageEventData StageEventData;
		StageEventData.Stage = StageToSet;
		OnNewStageEvent.Broadcast(StageEventData);
		DanceShowdown::GetManager().OnStageAdvancedEvent.Broadcast(StageEventData.Stage);

		#if !RELEASE
		TEMPORAL_LOG(this).Event("Set current stage to " + CurrentStage);
		#endif
	}

	void Activate()
	{
		bIsActive = true;
		BeatCounter = 0;
	}

	UFUNCTION(BlueprintCallable)
	void SetExplicitTimeStart()
	{
		ActivateTime = Time::GameTimeSeconds;
	}

	void Deactivate()
	{
		bIsActive = false;
	}

	bool IsActive() const
	{
		return bIsActive;
	}

	float GetActiveDuration() const
	{
		return Time::GetGameTimeSince(ActivateTime);
	}

	void Pause()
	{
		bIsPaused = true;
	}

	UFUNCTION()
	void Unpause(float Time)
	{
		bIsPaused = false;
		OnGameResumeEvent.Broadcast();
		CurrentMeasureData.bIsRestMeasure = true;
		float TimeSince = Time::GetRealTimeSince(Time);
		BeatCounter = (Math::RoundToInt(TimeSince / GetRealTimeBetweenBeats()) % DanceShowdown::BeatsPerMeasure) + 1;
		TimeSinceLastBeat = TimeSince % GetRealTimeBetweenBeats();
	}

	float GetBPM() const
	{
		switch(CurrentStage)
		{
			case 0:
				return DanceShowdown::BeatsPerMinuteStageOne;
			case 1:
				return DanceShowdown::BeatsPerMinuteStageTwo;
			case 2:
				return DanceShowdown::BeatsPerMinuteStageThree;
		}
		
		PrintError("No BPM setting exists for current stage");
		return DanceShowdown::BeatsPerMinuteStageOne;
	}

	float GetRealTimeBetweenBeats() const
	{
		return 1.0 / (GetBPM() / 60.0);
	}

	float GetRealMeasureTime() const
	{
		return GetRealTimeBetweenBeats() * DanceShowdown::BeatsPerMeasure;
	}

	int GetCurrentBeat() const
	{
		return BeatCounter;
	}

	bool IsVfxAnticipationBeat()
	{
		if(CurrentMeasureData.bIsRestMeasure)
			return BeatCounter == RestMeasureBeatLength -2;

		return false;
	}

	bool IsLastBeat() const
	{
		if(CurrentMeasureData.bIsRestMeasure)
			return BeatCounter == RestMeasureBeatLength;

		return BeatCounter == DanceShowdown::BeatsPerMeasure + 1;
	}

	float GetBeatAlpha() const
	{
		return TimeSinceLastBeat / GetRealTimeBetweenBeats();
	}

	float GetExplicitTime() const
	{
		int ExplicitTimeMultiplier;
		if (CurrentStage == 2)
			ExplicitTimeMultiplier = 5;
		else 
			ExplicitTimeMultiplier = 4;
		// float BeatDuration = 60 / (GetBPM() / ExplicitTimeMultiplier);
		float BeatDuration = 60 / (GetBPM() / ExplicitTimeMultiplier);
		//float BeatDuration = 60 / (70.0 / 6);
		float TimeInCurrentBeat = GetActiveDuration() % BeatDuration;
		float BeatAlpha = TimeInCurrentBeat / BeatDuration;
		return BeatAlpha;
	}

	float GetCurrentMeasureAlpha() const
	{
		return (GetActiveDuration() / GetRealMeasureTime()) % 1.0;
	}

	bool IsFirstMeasure() const
	{
		return CurrentMeasureData.Measure == 0;
	}

	bool IsRestMeasure()
	{
		return CurrentMeasureData.bIsRestMeasure;
	}
	
	bool IsMeasureDone() const
	{
		if(CurrentMeasureData.bIsRestMeasure)
			return BeatCounter >= RestMeasureBeatLength + 1;

		return BeatCounter >= DanceShowdown::BeatsPerMeasure + 1;
	}
}