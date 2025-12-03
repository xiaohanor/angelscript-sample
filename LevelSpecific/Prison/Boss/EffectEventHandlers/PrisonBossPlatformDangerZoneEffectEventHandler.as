UCLASS(Abstract)
class UPrisonBossPlatformDangerZoneEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Activate() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Explode() {}
}