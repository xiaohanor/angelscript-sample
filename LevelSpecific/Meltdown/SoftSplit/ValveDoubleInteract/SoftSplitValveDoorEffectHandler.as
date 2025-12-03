UCLASS(Abstract)
class USoftSplitValveDoorEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BothPlayersInteracted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MioStartPushing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MioStopPushing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ZoeStartPushing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ZoeStopPushing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BothPlayersStartPushing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BothPlayersStopPushing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Completed() {}
};