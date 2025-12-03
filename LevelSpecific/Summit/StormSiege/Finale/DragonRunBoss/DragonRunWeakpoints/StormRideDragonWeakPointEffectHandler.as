struct FStormRideWeakPointOnDestructionParams
{
	UPROPERTY()
	FVector Location;
	UPROPERTY()
	USceneComponent AttachComponent;
}

class UStormRideDragonWeakpointEffectHandler : UHazeEffectEventHandler
{
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ActivateDestruction(FStormRideWeakPointOnDestructionParams Params) {}
}