UCLASS(Abstract)
class USummitTopDownLaserCannonDestroyableWallEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDestroyed() {}
};