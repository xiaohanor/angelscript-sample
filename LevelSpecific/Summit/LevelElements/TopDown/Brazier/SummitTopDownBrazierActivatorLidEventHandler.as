UCLASS(Abstract)
class USummitTopDownBrazierActivatorLidEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLidStartOpening() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLidStopOpening() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLidStartClosing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLidStopClosing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStatueStartGoingUp() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStatueStartGoingDown() {}
};