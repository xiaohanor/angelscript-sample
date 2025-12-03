UCLASS(Abstract)
class UIslandOverseerLaserBombEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnExplode() {}
}