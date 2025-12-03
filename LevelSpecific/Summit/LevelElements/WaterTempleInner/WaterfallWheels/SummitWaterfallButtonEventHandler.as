UCLASS(Abstract)
class USummitWaterfallButtonEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnButtonPress() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnButtonUnPress() {}
};