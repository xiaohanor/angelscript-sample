UCLASS(Abstract)
class UMoonMarketFlyingWitchEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerStartSwinging(FMoonMarketInteractingPlayerEventParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerStopSwinging(FMoonMarketInteractingPlayerEventParams Params) {}
};