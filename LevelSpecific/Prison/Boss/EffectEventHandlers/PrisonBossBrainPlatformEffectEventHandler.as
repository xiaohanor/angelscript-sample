UCLASS(Abstract)
class UPrisonBossBrainPlatformEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartReveal() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FinishReveal() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartRetract() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FinishRetract() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BreakPlatform() {}
}