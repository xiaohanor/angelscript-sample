struct FPinballTargetEventHandlerParams
{
	UPROPERTY()
	TArray<UHazeSplineComponent> Splines;

	UPROPERTY()
	TArray<AHazeActor> Actors;
}

UCLASS(Abstract)
class UPinballTargetEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void EventSegmentDestroyed(FPinballTargetEventHandlerParams Params) {}
};