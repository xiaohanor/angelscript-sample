struct FMoonMarketThunderEventParams
{
	UPROPERTY()
	FVector StrikeLocation;
}

UCLASS(Abstract)
class UMoonMarketThunderCloudEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThunderStrike(FMoonMarketThunderEventParams Params) {}
};