struct FSolarFlareSwingWeightedPlatformParams
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	bool bIsMovingUp = false;
}

UCLASS(Abstract)
class USolarFlareSwingWeightPlatformEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWeightedPlatformStartMoving(FSolarFlareSwingWeightedPlatformParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWeightedPlatformStopMoving(FSolarFlareSwingWeightedPlatformParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWeightedPlatformTurnedOn(FSolarFlareSwingWeightedPlatformParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWeightedPlatformTurnedOff(FSolarFlareSwingWeightedPlatformParams Params)
	{
	}
};