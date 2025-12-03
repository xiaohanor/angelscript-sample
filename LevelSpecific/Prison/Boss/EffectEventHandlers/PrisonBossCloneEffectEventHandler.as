UCLASS(Abstract)
class UPrisonBossCloneEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Spawn() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Attack() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Destroy() {}
}