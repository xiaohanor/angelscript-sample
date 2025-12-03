UCLASS(Abstract)
class USplitTraversalDraggableFloatingPlatformEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnActivateBigThrusters() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDeactivateBigThrusters() {}
};