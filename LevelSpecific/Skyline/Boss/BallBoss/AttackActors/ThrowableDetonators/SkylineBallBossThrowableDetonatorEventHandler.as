class USkylineBallBossThrowableDetonatorEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpawned() 
	{
		// PrintToScreen("OnSpawned", 5.0);
	}

	// UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	// void OnBlink() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPickedUp() 
	{
		// PrintToScreen("OnPickedUp", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThrown() 
	{
		// PrintToScreen("OnThrown", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDetonate() 
	{
		// PrintToScreen("OnDetonate", 5.0);
	}
}