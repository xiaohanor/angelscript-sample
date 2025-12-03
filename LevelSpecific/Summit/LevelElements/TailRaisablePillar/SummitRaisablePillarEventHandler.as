UCLASS(Abstract)
class USummitRaisablePillarEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMoveUp() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMoveDown() {}
};