UCLASS(Abstract)
class UPrisonBossDonutEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Spawn() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FullySpawned() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Dissipate() {}
}