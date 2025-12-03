UCLASS(Abstract)
class USummitRollingObjectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDespawn() {}
};