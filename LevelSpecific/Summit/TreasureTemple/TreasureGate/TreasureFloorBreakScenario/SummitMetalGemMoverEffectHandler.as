struct FSummitMetalGemMoveParams
{
	UPROPERTY()
	FVector Location;
}

UCLASS(Abstract)
class USummitMetalGemMoverEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MetalGemMoveActivated(FSummitMetalGemMoveParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MetalGemMoveStopped(FSummitMetalGemMoveParams Params) {}
} 