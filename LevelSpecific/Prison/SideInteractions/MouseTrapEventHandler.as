UCLASS(Abstract)
class UMouseTrapEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnArmTrap() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSnapTrap() {}
};