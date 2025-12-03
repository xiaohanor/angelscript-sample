struct FMoonMarketCatEventParams
{
	UPROPERTY()
	int NewTotalCats;
}

UCLASS(Abstract)
class UMoonMarketCatEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCatStartCollecting(FMoonMarketInteractingPlayerEventParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCatCollected(FMoonMarketInteractingPlayerEventParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCatTotalUpdated(FMoonMarketCatEventParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartFloatingToGate() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMimicLidOpen() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMimicLidClosed() {}
};