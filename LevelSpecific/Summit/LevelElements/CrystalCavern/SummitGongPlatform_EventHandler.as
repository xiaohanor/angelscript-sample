UCLASS(Abstract)
class USummitGongPlatform_EventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MeltEffect()
	{
		
	}
};