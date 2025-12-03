UCLASS(Abstract)
class USoftSplitBridgeSciFiDestructionEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BridgeDestroyed() {}
};