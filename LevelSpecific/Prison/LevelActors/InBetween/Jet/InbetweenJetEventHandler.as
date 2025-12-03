UCLASS(Abstract)
class UInbetweenJetEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void JetStartCharge() {}

	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void JetLaunch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void JetStop() {}
};