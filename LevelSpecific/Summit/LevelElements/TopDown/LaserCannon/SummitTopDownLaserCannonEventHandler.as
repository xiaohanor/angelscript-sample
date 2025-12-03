UCLASS(Abstract)
class USummitTopDownLaserCannonEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaserActivated() {}
};