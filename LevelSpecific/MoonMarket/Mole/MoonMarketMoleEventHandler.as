UCLASS(Abstract)
class UMoonMarketMoleEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStep() {}
};