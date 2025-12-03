struct FImpactDestructibleRocksParams
{
	UPROPERTY()
	FVector Location;
}

UCLASS(Abstract)
class UAdultDragonImpactDestructibleRocksEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRockImpact(FImpactDestructibleRocksParams Params) {}
};