struct FWingSuitBarrelRollEffectParams
{
	UPROPERTY()
	int BarrelRollDirection;
}

UCLASS(Abstract)
class UWingSuitEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnActivateWingsuit() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDeactivateWingsuit() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBarrelRoll(FWingSuitBarrelRollEffectParams Params) {}
}