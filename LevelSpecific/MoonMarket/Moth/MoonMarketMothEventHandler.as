
UCLASS(Abstract)
class UMoonMarketMothEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMothStartDisintegrating() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMothStopDisintegrating() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMothStartAppearing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMothStopAppearing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartRiding(FMoonMarketInteractingPlayerEventParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopRiding(FMoonMarketInteractingPlayerEventParams Params) {}
};