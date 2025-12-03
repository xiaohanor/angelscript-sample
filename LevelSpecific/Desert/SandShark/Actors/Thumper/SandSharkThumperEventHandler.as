UCLASS(Abstract)
class USandSharkThumperEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThumpSuccess(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThumpFail(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFullyDown(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFullyReset(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerAttached(){}
};