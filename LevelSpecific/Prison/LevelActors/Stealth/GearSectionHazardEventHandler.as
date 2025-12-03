UCLASS(Abstract)
class UGearSectionHazardEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Activate() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Deactivate() {}
};