UCLASS(Abstract)
class UOilRigElevatorEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Start() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Stop() {}
}