UCLASS(Abstract)
class USummitExhalingDragonMouthEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMouthStartedBlowing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMouthStoppedBlowing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDragonStartedAscending() {}
};