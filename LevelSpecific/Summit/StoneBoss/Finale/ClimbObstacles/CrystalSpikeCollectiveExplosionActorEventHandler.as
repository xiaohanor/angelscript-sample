UCLASS(Abstract)
class UCrystalSpikeCollectiveExplosionActorEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnClusterDestroyed() {}
};