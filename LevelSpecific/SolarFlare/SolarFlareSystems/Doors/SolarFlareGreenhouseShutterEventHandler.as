UCLASS(Abstract)
class USolarFlareGreenhouseShutterEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShutterStopMoving()
	{		
	}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShutterStartMoving()
	{
	}
};