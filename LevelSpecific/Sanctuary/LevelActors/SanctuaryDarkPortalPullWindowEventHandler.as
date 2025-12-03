UCLASS(Abstract)
class USanctuaryDarkPortalPullWindowEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWindowGrabbed() 
	{
		DevPrintStringEvent("Pull Window", "OnWindowGrabbed");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWindowReleased() 
	{
		DevPrintStringEvent("Pull Window", "OnWindowReleased");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWindowThrown() 
	{
		DevPrintStringEvent("Pull Window", "OnWindowThrown");
	}
};