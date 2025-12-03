struct FSolarFlareGreenhouseDestructibleImpactParams
{
	UPROPERTY()
	FVector Location;
}

UCLASS(Abstract)
class USolarFlareGreenhouseDestructibleEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FlareImpact(FSolarFlareGreenhouseDestructibleImpactParams Params)
	{
	}
};