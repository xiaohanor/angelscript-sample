UCLASS(Abstract)
class UArenaElevatorEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopMoving() {}
}