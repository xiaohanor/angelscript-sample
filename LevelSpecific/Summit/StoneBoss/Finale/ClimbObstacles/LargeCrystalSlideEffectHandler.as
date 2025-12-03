struct FLargeCrystalRuptureParams
{
	UPROPERTY()
	FVector Location;
	FLargeCrystalRuptureParams(FVector NewLoc)
	{
		Location = NewLoc;
	}
}

UCLASS(Abstract)
class ULargeCrystalSlideEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LargeCrystalRupture(FLargeCrystalRuptureParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DestroyCrystalRupturedObjects(FLargeCrystalRuptureParams Params) {}
};