

class USkylineBallBossDetonatorSpawnerEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpawned() 
	{
		// PrintToScreen("OnSpawned", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact() 
	{
		// PrintToScreen("OnImpact", 5.0);
	}
}