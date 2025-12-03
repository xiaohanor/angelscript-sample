UCLASS(Abstract)
class UTeenDragonTreasureChestEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnChestExplode() {}
};