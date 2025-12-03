struct FOnButtonGrappleImpactParams
{
	UPROPERTY()
	FVector Location;
}

UCLASS(Abstract)
class UButtonGrapplePointEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnButtonGrappleImpact(FOnButtonGrappleImpactParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnButtonGrappleReturn(FOnButtonGrappleImpactParams Params) {}

};