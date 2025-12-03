UCLASS(Abstract)
class UGarbageTruckEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MovingUp() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MovingDown() {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FirstTimeOpen() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DoorOpening() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DoorFullyOpened() {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DoorClosing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DoorFullyClosed() {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HitHead() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartAlarm() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TrashCompactor_StartSequence() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TrashCompactor_Dock() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TrashCompactor_OpenHatches() {}
}