struct FStormCliffRockParams
{
	UPROPERTY()
	FVector Location;

	FStormCliffRockParams(FVector NewLocation)
	{
		Location = NewLocation;
	}
}

UCLASS(Abstract)
class UStormCliffRockEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLightningRockStruck(FStormCliffRockParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRockDestroyed(FStormCliffRockParams Params) {}
};