UCLASS(Abstract)
class UIslandOverseerCraneEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLiftStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLiftCompleted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDrop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMoveStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMoveStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLeaveFloodStart() {}
}