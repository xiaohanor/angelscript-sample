UCLASS(Abstract)
class UWingsuitBossMineEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMineSpawned() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMineHitWater() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMineExploded() {}
}