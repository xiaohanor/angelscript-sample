UCLASS(Abstract)
class UWingsuitBotProjectileEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMineSpawned() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMineExploded() {}
}