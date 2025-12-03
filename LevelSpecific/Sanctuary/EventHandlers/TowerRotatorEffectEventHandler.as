UCLASS(Abstract)
class UTowerRotatorEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartRotating() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopRotating() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ReactivateRotating() {}
}