UCLASS(Abstract)
class UPrisonBossZigZagEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Activate() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Dissipate() {}
}