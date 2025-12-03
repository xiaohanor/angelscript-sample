struct FSolarFlareGreenhouseLocomotiveNextSplineMoveEffectParams
{
	UPROPERTY()
	FVector  StopLocation;
}

struct FSolarFlareGreenhouseLocomotiveSolarFlareImpactEffectParams
{
	UPROPERTY()
	FVector ImpactLocation;
}

UCLASS(Abstract)
class USolarFlareGreenhouseLocomotiveEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGreenhouseLocomotiveStartNextSplineMove(FSolarFlareGreenhouseLocomotiveNextSplineMoveEffectParams Params) {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGreenhouseLocomotiveStopSplineMove(FSolarFlareGreenhouseLocomotiveNextSplineMoveEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGreenhouseLocomotiveSolarFlareImpact(FSolarFlareGreenhouseLocomotiveSolarFlareImpactEffectParams Params) {}
}