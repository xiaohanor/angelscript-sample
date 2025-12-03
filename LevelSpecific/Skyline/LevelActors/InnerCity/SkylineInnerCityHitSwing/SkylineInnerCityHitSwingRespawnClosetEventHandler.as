UCLASS(Abstract)
class USkylineInnerCityHitSwingRespawnClosetEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRespawnDoorOpening() 
	{
		// PrintToScreen("OnRespawnDoorOpening", 2.0, ColorDebug::Radioactive);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRespawnDoorOpen() 
	{
		// PrintToScreen("OnRespawnDoorOpen", 2.0, ColorDebug::Radioactive);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRespawnDoorClosing() 
	{
		// PrintToScreen("OnRespawnDoorClosing", 2.0, ColorDebug::Radioactive);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRespawnDoorClosed() 
	{
		// PrintToScreen("OnRespawnDoorClosed", 2.0, ColorDebug::Radioactive);
	}
};	
