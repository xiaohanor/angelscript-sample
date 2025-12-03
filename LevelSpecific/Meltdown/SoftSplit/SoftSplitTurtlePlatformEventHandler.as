UCLASS(Abstract)
class USoftSplitTurtlePlatformEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TurtleDrop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TurtleKill() {}
};