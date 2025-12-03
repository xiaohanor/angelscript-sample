struct FGreenhouseLiftParams
{
	UPROPERTY()
	FVector Location;
}

UCLASS(Abstract)
class USolarFlareGreenhouseLiftEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLiftStarted(FGreenhouseLiftParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLiftStopped(FGreenhouseLiftParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLiftOpenDoors(FGreenhouseLiftParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLiftImpacted(FGreenhouseLiftParams Params)
	{
	}
};