UCLASS(Abstract)
class UMoonMarketBabaYagaLanternEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnInteractionStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnInteractionCanceled() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLanternLit() {}
};