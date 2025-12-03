UCLASS(Abstract)
class UTundra_River_InteractableBushEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerHideInBush() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerExitBush() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTreeGuardianPutOnBushHat() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSnowMonkeyPutOnBushHat() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBushHatGetsDestroyed() {}
}