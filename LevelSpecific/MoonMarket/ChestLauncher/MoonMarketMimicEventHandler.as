UCLASS(Abstract)
class UMoonMarketMimicEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnKicked(FMoonMarketInteractingPlayerEventParams Params) {}
};