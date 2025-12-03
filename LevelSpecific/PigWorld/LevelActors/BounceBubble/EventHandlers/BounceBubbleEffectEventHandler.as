UCLASS(Abstract)
class UBounceBubbleEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BubbleSpawned() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlayerBounced() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BubbleBurstOnWall() {}
}