UCLASS(Abstract)
class USkylineInnerCityHitSwingEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBounceAgainstWall() 
	{
		// PrintToScreen("OnBounceAgainstWall", 2.0, ColorDebug::Radioactive);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBounceAgainstPlayer() 
	{
		// PrintToScreen("OnBounceAgainstPlayer", 2.0, ColorDebug::Radioactive);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFakeDestroyedAgainstEnvironment() 
	{
		// PrintToScreen("OnFakeDestroyedAgainstEnvironment", 2.0, ColorDebug::Radioactive);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRespawn() 
	{
		// PrintToScreen("OnRespawn", 2.0, ColorDebug::Radioactive);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLostRoofConnection() 
	{
		// PrintToScreen("OnLostRoofConnection", 2.0, ColorDebug::Radioactive);
	}
};	
