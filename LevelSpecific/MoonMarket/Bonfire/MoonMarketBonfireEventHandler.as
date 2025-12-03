UCLASS(Abstract)
class UMoonMarketBonfireEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFireLit() {}
};