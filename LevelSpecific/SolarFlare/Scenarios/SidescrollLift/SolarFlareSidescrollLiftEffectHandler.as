struct FSolarFlareSidescrollLiftParams
{
	UPROPERTY()
	FVector Location;
}

UCLASS(Abstract)
class USolarFlareSidescrollLiftEffectHandler : UHazeEffectEventHandler
{
	//Start
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLiftStarted(FSolarFlareSidescrollLiftParams Params)
	{
	}

	//Flare hit
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLiftFlareBreak(FSolarFlareSidescrollLiftParams Params)
	{
	}

	//Hits ground
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLiftCrash(FSolarFlareSidescrollLiftParams Params)
	{
	}
};