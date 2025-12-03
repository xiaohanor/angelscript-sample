UCLASS(Abstract)
class USolarFlareVOTunnleZiplineEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTunnelZiplineStarted()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTunnelZiplineImpact()
	{
	}
};