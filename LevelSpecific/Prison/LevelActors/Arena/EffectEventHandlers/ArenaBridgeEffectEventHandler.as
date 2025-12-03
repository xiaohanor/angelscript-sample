UCLASS(Abstract)
class UArenaBridgeEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartClosingFloorGates() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FinishClosingFloorGates() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartExtendingBridge() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FinishExtendingBridge() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartRetractingBridge() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FinishRetractingBridge() {}
}