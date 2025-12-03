UCLASS(Abstract)
class URemoteHackableCoffeeMachineEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartHacking() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopHacking() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartFilling() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopFilling() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Filled() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CoffeeDrunk() {}
}