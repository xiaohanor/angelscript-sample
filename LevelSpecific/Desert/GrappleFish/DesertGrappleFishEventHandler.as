struct FGrappleFishSandSurfaceBreachedParams
{
	UPROPERTY()
	FVector SandBreachLocation;
}

UCLASS(Abstract)
class UDesertGrappleFishEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartSwimming() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopSwimming() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDiveStarted(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDiveSandSurfaceBreached(FGrappleFishSandSurfaceBreachedParams Params){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnResurface(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFinalJumpStarted(){}
}