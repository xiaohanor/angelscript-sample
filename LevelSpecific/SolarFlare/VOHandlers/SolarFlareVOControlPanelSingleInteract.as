UCLASS(Abstract)
class USolarFlareVOControlPanelSingleInteract : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPanelInteracted()
	{
	}
};