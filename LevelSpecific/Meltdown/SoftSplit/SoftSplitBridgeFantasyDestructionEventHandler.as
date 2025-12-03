UCLASS(Abstract)
class USoftSplitBridgeFantasyDestructionEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DestroyFantasyBridge() {}
};