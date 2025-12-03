UCLASS(Abstract)
class UMaxSecurityLaserHellEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DoorAlarmStart(FLaserHellDoorEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DoorAlarmStop(FLaserHellDoorEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DoorOpened(FLaserHellDoorEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DoorClosed(FLaserHellDoorEventData Data) {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LaserShot(FLaserHellLaserAlarmEventData Data) {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ButtonPressed(FLaserHellButtonEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ButtonReleased(FLaserHellButtonEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ElevatorGoingUp(FLaserHellElevatorEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ElevatorGoingDown(FLaserHellElevatorEventData Data) {}
};

struct FLaserHellDoorEventData
{
	UPROPERTY()
	AMaxSecurityLaserHellDoor DoorActor;
};

struct FLaserHellLaserAlarmEventData
{
	UPROPERTY()
	AMaxSecurityLaserHellLaserAlarm LaserAlarmActor;
};

struct FLaserHellButtonEventData
{
	UPROPERTY()
	AMaxSecurityPressurePlate PressurePlate;
};

struct FLaserHellElevatorEventData
{
	UPROPERTY()
	AMaxSecurityLaserHellElevator Elevator;
};