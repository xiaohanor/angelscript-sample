UCLASS(Abstract)
class USpaceWalkDoorEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OpenDoor() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DoorOpened() {}
};