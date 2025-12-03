UCLASS(Abstract)
class USummitFruitPressStatueWheelsEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWheelStarted() {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWheelStopped() {}
};