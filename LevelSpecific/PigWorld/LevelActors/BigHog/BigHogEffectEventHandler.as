UCLASS(Abstract)
class UBigHogEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HitBelly() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartFarting() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopFarting() {}
}