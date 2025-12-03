UCLASS(Abstract)
class UMoonMarketMushroomPeopleEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBouncedOn() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStep() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopRunning() {}
};