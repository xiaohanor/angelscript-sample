UCLASS(Abstract)
class UGarbageTruck_BackDropEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartMoving() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopMoving() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopForGarbage() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ResumeAfterGarbageStop() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Reset() {}
}