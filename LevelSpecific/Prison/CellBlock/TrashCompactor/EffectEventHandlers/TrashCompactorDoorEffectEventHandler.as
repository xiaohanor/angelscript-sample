UCLASS(Abstract)
class UTrashCompactorDoorEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OpenDoor() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CloseDoor() {}
}