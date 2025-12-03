UCLASS(Abstract)
class UAlienCruiserDestructionPlatformEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlatformDestroyed() {}
};