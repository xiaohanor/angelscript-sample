UCLASS(Abstract)
class UIslandSidescrollerBlockingDoorEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartOpen() 
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartClosing() 
	{
	}
}