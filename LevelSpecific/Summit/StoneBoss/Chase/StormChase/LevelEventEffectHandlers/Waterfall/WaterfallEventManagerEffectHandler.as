UCLASS(Abstract)
class UWaterfallEventManagerEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDragonsWaterEnter() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDragonsWaterExit() {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStoneBeastWaterExit() {}
};