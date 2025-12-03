struct FSummitTailWeighDownElevatorConstraintHitParams
{
	// How fast it hits (0 -> 1)
	UPROPERTY()
	float HitStrength = 0.0;
}

UCLASS(Abstract)
class USummitTailWeighDownElevatorEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartedMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStoppedMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitConstraintTop(FSummitTailWeighDownElevatorConstraintHitParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitConstraintBottom(FSummitTailWeighDownElevatorConstraintHitParams Params) {}
};