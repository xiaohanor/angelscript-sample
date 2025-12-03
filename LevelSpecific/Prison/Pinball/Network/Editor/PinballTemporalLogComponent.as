#if EDITOR
struct FPinballTemporalLogFrameData
{
	FHazeRange PredictionTimeRange;
	TArray<float> SubframeTimes;
};

class UPinballTemporalLogComponent : UActorComponent
{
	default bIsEditorOnly = true;

	TMap<uint, FPinballTemporalLogFrameData> LogFrameToFrameDataMap;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto Manager = Pinball::Prediction::GetManager();
		Manager.PreInit.AddUFunction(this, n"PreInit");
		Manager.PreSubTick.AddUFunction(this, n"PreSubTick");
		Manager.PostFinalize.AddUFunction(this, n"PostFinalize");
	}

	UFUNCTION()
	private void PreInit(uint InFrameNumber, float InPredictionTime)
	{
		const auto TemporalLog = UHazeTemporalLog::Get();
		if(TemporalLog == nullptr)
			return;

		const uint LogFrame = uint(TemporalLog.CurrentLogFrameNumber);

		FPinballTemporalLogFrameData& FrameData = LogFrameToFrameDataMap.FindOrAdd(LogFrame);
		FrameData.PredictionTimeRange.Min = InPredictionTime;
	}

	UFUNCTION()
	private void PreSubTick(uint InFrameNumber, uint InSubframeNumber, float InPredictionTime, float InDeltaTime)
	{
		const auto TemporalLog = UHazeTemporalLog::Get();
		if(TemporalLog == nullptr)
			return;

		const uint LogFrame = uint(TemporalLog.CurrentLogFrameNumber);

		FPinballTemporalLogFrameData& FrameData = LogFrameToFrameDataMap.FindOrAdd(LogFrame);
		FrameData.SubframeTimes.Add(InPredictionTime);
	}

	UFUNCTION()
	private void PostFinalize(float InPredictionTime)
	{
		const auto TemporalLog = UHazeTemporalLog::Get();
		if(TemporalLog == nullptr)
			return;

		const uint LogFrame = uint(TemporalLog.CurrentLogFrameNumber);
		
		FPinballTemporalLogFrameData& FrameData = LogFrameToFrameDataMap.FindOrAdd(LogFrame);
		FrameData.PredictionTimeRange.Max = InPredictionTime;
	}

	FPinballTemporalLogFrameData GetFrameData(uint LogFrame) const
	{
		FPinballTemporalLogFrameData FrameData;
		LogFrameToFrameDataMap.Find(LogFrame, FrameData);
		return FrameData;
	}
};
#endif