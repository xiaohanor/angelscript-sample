UCLASS(Abstract)
class USpaceWalkOxygenEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OxygenMeterWidgetShown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OxygenPipConsumed() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OxygenPipRefilled() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OxygenLowWarningAdded() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OxygenLowWarningRemoved() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OxygenDeathTriggered() {}
};