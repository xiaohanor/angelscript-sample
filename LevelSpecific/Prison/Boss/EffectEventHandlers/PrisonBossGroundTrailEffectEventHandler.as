UCLASS(Abstract)
class UPrisonBossGroundTrailEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Spawn() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Explode() {}
}