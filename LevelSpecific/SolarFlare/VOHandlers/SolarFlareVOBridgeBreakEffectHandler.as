struct FOnSolarFlareVOBridgeBreakParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

UCLASS(Abstract)
class USolarFlareVOBridgeBreakEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSolarPanelBreak(FOnSolarFlareVOBridgeBreakParams Params)
	{

	}
};