struct FDarkCaveOrnamentActivatedParams
{
	UPROPERTY()
	FVector Location;
}

UCLASS(Abstract)
class UDarkCaveDragonOrnamentEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OrnamentActivated(FDarkCaveOrnamentActivatedParams Params) {}
};