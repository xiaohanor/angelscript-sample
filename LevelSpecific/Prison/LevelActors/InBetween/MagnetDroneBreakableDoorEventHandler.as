UCLASS(Abstract)
class UMagnetDroneBreakableDoorEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FirstHitEvent() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SecondHitEvent() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DoorHitFloorEvent() {}
};