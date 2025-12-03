struct FCongaLineOnBeatEventData
{
	int Beat;
	int Measure;
	bool bIsPoseBeat;

	bool IsFirstBeat() const
	{
		return Beat == 1;
	}
}

struct FCongaLineOnMeasureEventData
{
	bool SucceededAll;
	bool bIsRestMeasure = true;
}


event void FCongaLineOnCongaStartedEvent();
event void FCongaLineOnBeatEvent(FCongaLineOnBeatEventData EventData);
event void FCongaLineOnHalfBeatEvent(FCongaLineOnBeatEventData EventData);
event void FCongaLineOnMeasureEvent(FCongaLineOnMeasureEventData EventData);
event void FCongaLineOnToggleActiveEvent(bool bIsActive);
event void FCongaLineOnMonkeyBarFilledEvent();
event void FCongaLineOnMonkeyBarLostEvent();
event void FCongaLineOnMonkeyGainedEvent(int TotalMonkeyAmount);
event void FCongaLineOnMonkeyLostEvent(int TotalMonkeyAmount);
event void FCongaLineOnMonkeyAmountChangedEvent(int TotalMonkeyAmount);
event void FCongaLineOnTimeRunOutEvent();
event void FCongaLineOnWinEvent();

/**
 * The manager is an actor here to allow putting a UHazeRequestCapabilityOnPlayerComponent on it
 * This makes it easy to add the conga line to a level, we just place this manager in the level and boom, it's set up
 */
UCLASS(Abstract)
class ACongaLineManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;

	UPROPERTY()
	FCongaLineOnCongaStartedEvent OnCongaStartedEvent;

	UPROPERTY()
	FCongaLineOnBeatEvent OnBeatEvent;

	UPROPERTY()
	FCongaLineOnBeatEvent OnRoundedBeatEvent;
	
	UPROPERTY()
	FCongaLineOnMeasureEvent OnMeasureEvent;

	UPROPERTY()
	FCongaLineOnWinEvent OnWinEvent;

	//private UCongaLineMonkeyProgressBar MonkeyProgressBar;
	UPROPERTY(DefaultComponent)
	UCongaLineMonkeyCounter MonkeyCounter;

	FCongaLineOnMeasureEventData CurrentMeasureData;


	bool bIsToggleActive = false;
	FCongaLineOnToggleActiveEvent OnToggleActiveEvent;

	UPROPERTY()
	FCongaLineOnMonkeyGainedEvent OnMonkeyGainedEvent;

	UPROPERTY()
	FCongaLineOnMonkeyLostEvent OnMonkeyLostEvent;

	UPROPERTY()
	FCongaLineOnMonkeyAmountChangedEvent OnMonkeyAmountChangedEvent;

	UPROPERTY()
	FCongaLineOnMonkeyBarFilledEvent OnMonkeyBarFilledEvent;

	UPROPERTY()
	FCongaLineOnMonkeyBarLostEvent OnMonkeyBarLostEvent;

	UPROPERTY()
	FCongaLineOnTimeRunOutEvent OnTimeRunOutEvent;

	TArray<ACongaLineMonkey> AllMonkeys;

	bool bIsSnake = true;
	bool bDisperseAllMonkeysOnLineCutoff = false;
	bool bShouldCollide = true;
	bool bIsCompleted = false;

	private bool bIsActive = false;
	private float ActivateTime;
	private int BeatCounter = 0;
	private int RoundedBeatCounter = 0;
	private int MeasureCounter = 0;
	float CurrentVibe = CongaLine::VibeMeterStartValue;

	private int CurrentStage = 0;
	private int StageToSet = 0;

	uint MioInRangeOfInteractableFrame = 0;

	void SetStage(int NewStage)
	{
		StageToSet = NewStage;
	}

	void SetMonkeyAmountForPlayer(int NewMonkeyAmount, EMonkeyColorCode ColorCode, bool GainedMonkey)
	{
		MonkeyCounter.SetMonkeyAmount(NewMonkeyAmount, ColorCode, GainedMonkey);
	}

	void AddMonkey(ACongaLineMonkey Monkey)
	{
		AllMonkeys.Add(Monkey);
		Monkey.MeshComp.SetVisibility(false);
	}

	UFUNCTION(BlueprintCallable)
	void ShowAllMonkeys()
	{
		for(auto Monkey : AllMonkeys)
			Monkey.MeshComp.SetVisibility(true);
	}

	UFUNCTION(BlueprintCallable)
	void HideAllMonkeys()
	{
		for(auto Monkey : AllMonkeys)
			Monkey.MeshComp.SetVisibility(false);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CongaLine::IgnoreCollisions.MakeVisible();
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!HasControl())
			return;

		if(!IsActive())
			return;



		while(BeatCounter < GetCurrentBeat(false))
		{
			BeatCounter++;
			int CurrentMeasure = GetMeasure(BeatCounter);
			if(MeasureCounter != CurrentMeasure)
			{
				CurrentStage = StageToSet;

				MeasureCounter = CurrentMeasure;
				OnMeasureEvent.Broadcast(CurrentMeasureData);
				CurrentMeasureData.SucceededAll = true;
				CurrentMeasureData.bIsRestMeasure = !CurrentMeasureData.bIsRestMeasure;
			}

			FCongaLineOnBeatEventData EventData;
			EventData.Beat = WrapBeat(BeatCounter);
			EventData.Measure = CurrentMeasure;
			EventData.bIsPoseBeat = IsBeatPose(BeatCounter);
			OnBeatEvent.Broadcast(EventData);
		}

		while(RoundedBeatCounter < GetRoundedBeat(false))
		{
			RoundedBeatCounter++;

			FCongaLineOnBeatEventData EventData;
			EventData.Beat = WrapBeat(RoundedBeatCounter);
			EventData.Measure = GetMeasure(RoundedBeatCounter);
			EventData.bIsPoseBeat = IsBeatPose(RoundedBeatCounter);
			OnRoundedBeatEvent.Broadcast(EventData);
		}


	#if EDITOR
		LogToTemporalLog();
	#endif
	}
	
	bool WasMioInRangeThisFrame() const
	{
		return MioInRangeOfInteractableFrame >= Time::FrameNumber - 1;
	}

	void FailMeasure()
	{
		CurrentMeasureData.SucceededAll = false;
	}

	void Activate()
	{
		
		bIsActive = true;
		
		ActivateTime = Time::GameTimeSeconds;
		BeatCounter = 0;

		OnCongaStartedEvent.Broadcast();
		//MonkeyProgressBar = Game::Mio.AddWidget(MonkeyProgressBarClass);
	}

	void Deactivate()
	{
		bIsActive = false;
		//Game::Mio.RemoveWidget(MonkeyProgressBar);
	}

	bool IsActive() const
	{
		return bIsActive;
	}

	float GetActiveDuration() const
	{
		//check(IsActive());
		return Time::GetGameTimeSince(ActivateTime);
	}

	float GetRealTimeBetweenBeats() const
	{
		return 1.0 / ((CongaLine::BeatsPerMinute + CongaLine::AdditionalBeatsPerStage * CurrentStage) / 60.0);
	}

	float GetRealMeasureTime() const
	{
		return GetRealTimeBetweenBeats() * CongaLine::BeatsPerMeasure;
	}

	int GetRoundedBeat(bool bWrap) const
	{
		const int RoundedBeat = Math::RoundToInt(GetActiveDuration() / GetRealTimeBetweenBeats());
		if(bWrap)
			return WrapBeat(RoundedBeat);
		else
			return RoundedBeat;
	}

	int GetCurrentBeat(bool bWrap) const
	{
		const int CurrentBeat = Math::CeilToInt(GetActiveDuration() / GetRealTimeBetweenBeats());
		if(bWrap)
			return WrapBeat(CurrentBeat);
		else
			return CurrentBeat;
	}

	void ActivationToggle(bool bShouldActivate)
	{
		if(bIsToggleActive == bShouldActivate)
			return;

		Print("Toggle");
		bIsToggleActive = bShouldActivate;
		OnToggleActiveEvent.Broadcast(bIsToggleActive);
	}

	int WrapBeat(int Beat) const
	{
		return Math::WrapIndex(Beat, 1, CongaLine::BeatsPerMeasure+1);
	}

	float GetBeatAlpha() const
	{
		return (GetActiveDuration() / GetRealTimeBetweenBeats()) % 1.0;
	}

	int GetCurrentMeasure() const
	{
		return Math::IntegerDivisionTrunc(GetCurrentBeat(false) - 1, CongaLine::BeatsPerMeasure);
	}

	int GetMeasure(int Beat) const
	{
		return Math::IntegerDivisionTrunc(Beat - 1, CongaLine::BeatsPerMeasure);
	}

	float GetCurrentMeasureAlpha() const
	{
		return (GetActiveDuration() / GetRealMeasureTime()) % 1.0;
	}

	bool IsCurrentBeatPose() const
	{
		return GetCurrentBeat(true) == CongaLine::BeatsPerMeasure;
	}

	bool IsBeatPose(int Beat) const
	{
		return WrapBeat(Beat) == CongaLine::BeatsPerMeasure;
	}

	bool IsFirstMeasure() const
	{
		return GetCurrentMeasure() == 1;
	}

	UFUNCTION(BlueprintPure)
	void GetAmountOfMonkeys(int&out MioAmount, int&out ZoeAmount)
	{
		MioAmount = MonkeyCounter.MioMonkeyAmount;
		ZoeAmount = MonkeyCounter.ZoeMonkeyAmount;
	}


	#if EDITOR
	private void LogToTemporalLog() const
	{
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);

		TemporalLog.Value("Is Active", IsActive());
		TemporalLog.Value("Activate Time", ActivateTime);
		TemporalLog.Value("Active Duration", GetActiveDuration());

		TemporalLog.Value("Beat;Current Beat", GetCurrentBeat(true));
		TemporalLog.Value("Beat;Beat Alpha", GetBeatAlpha());

		TemporalLog.Value("Measure;Current Measure", GetCurrentMeasure());
		TemporalLog.Value("Measure;Measure Alpha", GetCurrentMeasureAlpha());

		TemporalLog.Value("Pose;Is Pose Beat", IsCurrentBeatPose());
	}
	#endif
};