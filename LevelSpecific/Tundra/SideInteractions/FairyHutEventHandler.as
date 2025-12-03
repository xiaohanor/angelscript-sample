UCLASS(Abstract)
class UFairyHutEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DoorOpen() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DoorClose() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MonkeySlamHut() {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FirePlaceOn() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FirePlaceOff() {}
};