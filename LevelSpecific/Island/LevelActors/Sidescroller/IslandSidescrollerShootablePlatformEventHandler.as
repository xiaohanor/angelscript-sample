UCLASS(Abstract)
class UIslandSidescrollerShootablePlatformEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HitPlatform() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlatformMovingUp() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlatformMovingDown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FullyUp() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FullyDown() {}
}