UCLASS(Abstract)
class USplitTraversalPushableMushroomEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBounce() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitConstraint(FSplitTraversalPushableMushroomImpact EventData) {}
}