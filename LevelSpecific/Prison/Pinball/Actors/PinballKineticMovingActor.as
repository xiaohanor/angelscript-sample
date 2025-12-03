UCLASS(NotBlueprintable)
class APinballKineticMovingActor : AKineticMovingActor
{
	default NetworkMode = EKineticMovementNetwork::PredictedToZoeControl;

	UPROPERTY(DefaultComponent)
	UPinballPredictionRecordTransformComponent RecordTransformComp;
	default RecordTransformComp.bRemoveHalfPing = false;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;

	UPROPERTY(DefaultComponent)
	UPinballTemporalLogSubframeTransformLoggerComponent SubframeTransformLoggerComp;
#endif
};