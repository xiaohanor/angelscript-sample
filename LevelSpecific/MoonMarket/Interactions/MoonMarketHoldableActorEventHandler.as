UCLASS(Abstract)
class UMoonMarketHoldableActorEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPickup(FMoonMarketInteractingPlayerEventParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDespawn(FMoonMarketInteractingPlayerEventParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRespawn(FMoonMarketInteractingPlayerEventParams Params)
	{
	}
};