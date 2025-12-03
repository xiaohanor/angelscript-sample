struct FIslandLockPickingPuzzleBoltGenericEffectParams
{
	UPROPERTY()
	AIslandLockPickingPuzzleBolt Bolt;
}

struct FIslandLockPickingPuzzleBoltMoveEffectParams
{
	UPROPERTY()
	AIslandLockPickingPuzzleBolt Bolt;

	UPROPERTY()
	EIslandLockPickingPuzzleBoltMoveType MoveType;
}

struct FIslandLockPickingPuzzleBoltBoltHitPinEffectParams
{
	UPROPERTY()
	AIslandLockPickingPuzzleBolt Bolt;

	UPROPERTY()
	AIslandLockPickingPuzzlePin Pin;
}

UCLASS(Abstract)
class UIslandLockPickingPuzzleBoltEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBoltStartMoving(FIslandLockPickingPuzzleBoltMoveEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBoltStopMoving(FIslandLockPickingPuzzleBoltMoveEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBoltHitPin(FIslandLockPickingPuzzleBoltBoltHitPinEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPanelStartMoving(FIslandLockPickingPuzzleBoltGenericEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPanelStopMoving(FIslandLockPickingPuzzleBoltGenericEffectParams Params) {}
}