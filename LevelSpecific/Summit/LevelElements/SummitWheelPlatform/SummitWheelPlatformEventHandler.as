struct FSummitWheelPLatformStartedTiltingParams
{
	UPROPERTY()
	USceneComponent ComponentWhichStartedTilting;
}

UCLASS(Abstract)
class USummitWheelPlatformEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlatformStartedTilting(FSummitWheelPLatformStartedTiltingParams Params) {}
};