class UOilRigForceFieldSpinnerBatteryPlayerComponent : UActorComponent
{
	AHazePlayerCharacter Player;
	AOilRigForceFieldSpinnerBattery Battery;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}
}