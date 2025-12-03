UCLASS(Abstract)
class UPrisonBossWaveSlashEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Launch() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Dissipate() {}
}