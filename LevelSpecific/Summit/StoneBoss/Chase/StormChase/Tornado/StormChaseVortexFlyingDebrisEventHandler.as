struct FStormChaseVortexFlyingDebrisParams
{
	UPROPERTY()
	FVector Location;

	FStormChaseVortexFlyingDebrisParams(FVector NewLocation)
	{
		Location = NewLocation;
	}
}

UCLASS(Abstract)
class UStormChaseVortexFlyingDebrisEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnVortexDebrisEventStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnVortexDebrisPlayerImpact(FStormChaseVortexFlyingDebrisParams Params) {}
};