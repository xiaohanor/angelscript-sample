UCLASS(Abstract)
class UMoonMarketGardenGateEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGateOpened() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPatternRemoved() {}
};