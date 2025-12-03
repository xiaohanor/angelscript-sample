UCLASS(Abstract)
class URemoteHackableCoffeeMachinePlayerEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CoffeeDrunk() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CoffeeTick(FRemoteHackableCoffeeMachinePlayerEffectEventHandlerParams Params) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CoffeeSubsided() {}
}

struct FRemoteHackableCoffeeMachinePlayerEffectEventHandlerParams
{
	UPROPERTY()
	float TimeDilation = 1.0;
}