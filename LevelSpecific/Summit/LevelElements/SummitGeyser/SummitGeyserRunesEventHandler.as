UCLASS(Abstract)
class USummitGeyserRunesEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStatueStartedMovingUp() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStatueStoppedMovingUp() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStatueStartedMovingDown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStatueStoppedMovingDown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLidStartedOpening() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLidStoppedOpening() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLidStartedClosing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLidStoppedClosing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGeyserBecameBlocked() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGeyserStoppedBeingBlocked() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerLaunched(FSummitGeyserOnPlayerLaunchedParams Params) {}
};