UCLASS(Abstract)
class UPrisonBossBrainEyeEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RipOut() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Magnetized() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Demagnetized() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Weakened() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartReturnToSocket() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ReturnedToSocket() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DetachFromSocket() {}
}