class USkylineInnerCityTelevatorEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnButtonClicked() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnElevatorStartMoving() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnElevatorStartMovingToRoof() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnElevatorStopMoving() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoorOpen() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoorOpenAtDestination() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoorClose() {};
}