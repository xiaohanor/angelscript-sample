UCLASS(Abstract)
class UTeenDragonEatingEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartEating() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnObjectEaten() {}
	
};