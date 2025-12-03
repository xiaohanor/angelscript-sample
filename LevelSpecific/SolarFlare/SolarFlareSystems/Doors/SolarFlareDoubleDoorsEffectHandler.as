struct FSolarFlareDoubleDoorsParams
{
	UPROPERTY()
	FVector Location;
}

UCLASS(Abstract)
class USolarFlareDoubleDoorsEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoorsOpen(FSolarFlareDoubleDoorsParams Params) 
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDoorsClose(FSolarFlareDoubleDoorsParams Params) 
	{
	}
};