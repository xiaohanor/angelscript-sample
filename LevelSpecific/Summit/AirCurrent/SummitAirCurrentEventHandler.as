UCLASS(Abstract)
class USummitAirCurrentEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartedBlowing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStoppedBlowing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDragonStartedAscending() {}
};