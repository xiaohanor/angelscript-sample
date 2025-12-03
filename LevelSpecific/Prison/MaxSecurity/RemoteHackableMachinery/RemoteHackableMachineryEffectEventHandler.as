UCLASS(Abstract)
class URemoteHackableMachineryEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FullyRetracted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FullyExtended() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartMovingOutwards() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartMovingInwards() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Break() {}
}