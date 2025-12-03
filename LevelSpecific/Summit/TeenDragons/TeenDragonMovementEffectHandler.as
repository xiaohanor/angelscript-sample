UCLASS(Abstract)
class UTeenDragonMovementEffectHandler : UHazeEffectEventHandler
{
	// Will get called when the dragon was airborne but is now grounded
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLand() {}
}