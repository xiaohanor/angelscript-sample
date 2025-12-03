class UPoolSideWaterJetEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnJetActivated(FPoolSideJetEventParams Params)
	{

	}	

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnJetDeactivated(FPoolSideJetEventParams Params)
	{
		
	}
}

struct FPoolSideJetEventParams
{
	ESkylineWaterJetType JetType;
}