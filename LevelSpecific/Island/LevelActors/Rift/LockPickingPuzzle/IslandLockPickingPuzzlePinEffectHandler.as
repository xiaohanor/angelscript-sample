struct FIslandLockPickingPuzzlePinGenericEffectParams
{
	UPROPERTY()
	AIslandLockPickingPuzzlePin Pin;
}

UCLASS(Abstract)
class UIslandLockPickingPuzzlePinEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPinHitHighestPoint(FIslandLockPickingPuzzlePinGenericEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPinHitLowestPoint(FIslandLockPickingPuzzlePinGenericEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPinStoppedByBolt(FIslandLockPickingPuzzlePinGenericEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPinStartMovingAgain(FIslandLockPickingPuzzlePinGenericEffectParams Params) {}
}