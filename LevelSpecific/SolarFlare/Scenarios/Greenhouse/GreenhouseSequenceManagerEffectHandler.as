UCLASS(Abstract)
class UGreenhouseSequenceManagerEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGlassBreak() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCompleteDestruction() {}
};