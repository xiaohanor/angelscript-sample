UCLASS(Abstract)
class UShootableSpinningTargetEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpinStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpinStop() {}
}