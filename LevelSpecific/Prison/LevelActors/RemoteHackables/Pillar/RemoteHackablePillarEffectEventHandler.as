UCLASS(Abstract)
class URemoteHackablePillarEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Hacked() {}
}