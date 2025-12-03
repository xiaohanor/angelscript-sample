struct FSummitRaisableManagerData
{
	UPROPERTY()
	float Alpha;

	FSummitRaisableManagerData (float NewAlpha)
	{
		Alpha = NewAlpha;
	}
}

UCLASS(Abstract)
class USummitRaisableManagerEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTimerStart() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTimerStop() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTimerUpdate(FSummitRaisableManagerData Params) {}
};