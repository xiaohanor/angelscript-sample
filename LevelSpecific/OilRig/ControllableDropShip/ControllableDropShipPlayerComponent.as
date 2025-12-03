class UControllableDropShipPlayerComponent : UActorComponent
{
	AHazePlayerCharacter Player;

	AControllableDropShip CurrentDropShip;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}
}