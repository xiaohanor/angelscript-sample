UCLASS(Abstract)
class UMeltdownWorldSpinBridgeDestroyEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BridgeDestruction() {}
};