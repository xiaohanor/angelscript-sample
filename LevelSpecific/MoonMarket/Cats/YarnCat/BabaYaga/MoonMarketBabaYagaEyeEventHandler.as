UCLASS(Abstract)
class UMoonMarketBabaYagaEyeEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTargetedPlayer() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBlink() {}
};