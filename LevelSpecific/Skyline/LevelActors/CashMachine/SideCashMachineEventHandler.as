
UCLASS(Abstract)
class USideCashMachineEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBreak() {}
}