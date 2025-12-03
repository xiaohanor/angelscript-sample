UCLASS(Abstract)
class UPrisonBossBrainEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MagneticBlastTriggered() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OpenBrain() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CloseBrain() {}
}