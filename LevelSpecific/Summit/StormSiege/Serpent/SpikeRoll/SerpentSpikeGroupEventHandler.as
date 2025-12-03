UCLASS(Abstract)
class USerpentSpikeGroupEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpikeGroupGrow() {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpikeGroupSmash() {}
};