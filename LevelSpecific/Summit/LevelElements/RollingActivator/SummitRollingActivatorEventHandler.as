UCLASS(Abstract)
class USummitRollingActivatorEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHit(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnActivated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReachedFurthestIn() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReset() {}
};