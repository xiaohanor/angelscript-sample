#if EDITOR
delegate void FPinballTemporalLogSubframeTransformLoggerOnScrubComponentDelegate(FTransform WorldTransform);

/** 
 * Will play back recorded transforms when scrubbing in the temporal log
 */
UCLASS(NotBlueprintable)
class UPinballTemporalLogSubframeTransformLoggerComponent : UHazeTemporalLogScrubbableComponent
{
	default bIsEditorOnly = true;

	UPinballPredictionRecordTransformComponent RecordTransformComponent;

	// Hack to also move the player along with the proxy
	FPinballTemporalLogSubframeTransformLoggerOnScrubComponentDelegate OnScrubToSubframeDelegate;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(!Network::IsGameNetworked())
		{
			DestroyComponent(this);
			return;
		}

		if(!Pinball::GetPaddlePlayer().HasControl())
		{
			DestroyComponent(this);
			return;
		}

		if(!Pinball::Prediction::bPredictionLogsSubframes)
		{
			DestroyComponent(this);
			return;
		}

		RecordTransformComponent = UPinballPredictionRecordTransformComponent::Get(Owner);
	}

	void ScrubToPredictionTime(float PredictionTime)
	{
		RecordTransformComponent.PlaybackTransformAtTime(PredictionTime);

		if(OnScrubToSubframeDelegate.IsBound())
			OnScrubToSubframeDelegate.Execute(RecordTransformComponent.AttachParent.WorldTransform);
	}

	UFUNCTION(BlueprintOverride)
	void OnTemporalLogStopScrubbing(UHazeTemporalLog Log)
	{
		if(RecordTransformComponent == nullptr)
			return;

		auto TransformLoggerComp = UTemporalLogTransformLoggerComponent::Get(Owner);
		if(TransformLoggerComp != nullptr)
			return;

		RecordTransformComponent.ResetTransformToCurrent();

		// No need to call OnScrubToSubframeDelegate since other actors should reset using the temporal log transform logger comp
	}
};
#endif