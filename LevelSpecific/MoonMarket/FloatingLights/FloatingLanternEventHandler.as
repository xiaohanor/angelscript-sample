UCLASS(Abstract)
class UFloatingLanternEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerLanded() {}
};