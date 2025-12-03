UCLASS(Abstract)
class USolarFlareBatteryLiftEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMove() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopMove() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMovingUp() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMovingDown() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReachedTop() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReachedBottom() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoubleInteractUsed() {}
};