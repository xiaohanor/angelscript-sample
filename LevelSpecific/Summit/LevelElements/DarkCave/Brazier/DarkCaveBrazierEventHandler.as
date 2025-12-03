UCLASS(Abstract)
class UDarkCaveBrazierEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFireStarted() {}
};