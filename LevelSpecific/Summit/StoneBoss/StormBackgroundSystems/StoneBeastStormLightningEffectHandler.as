struct FStoneBeastStormLightingParams
{
	UPROPERTY()
	FVector Location;
}

UCLASS(Abstract)
class UStoneBeastStormLightningEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SpawnLightning(FStoneBeastStormLightingParams Params) {}
};