UCLASS(Abstract)
class USummitSmashapultGlobEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPrime() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSplatter() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDissolveByAcid() {}
}


