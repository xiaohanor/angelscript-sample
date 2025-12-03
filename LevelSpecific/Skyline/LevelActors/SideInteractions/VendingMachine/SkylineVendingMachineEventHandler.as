UCLASS(Abstract)
class USkylineVendingMachineEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HitByKatana() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void VendingMachineBroken() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SpawnedCan() {}
};