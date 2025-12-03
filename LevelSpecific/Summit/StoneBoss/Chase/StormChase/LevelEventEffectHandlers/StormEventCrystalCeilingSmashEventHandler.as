struct FStormEventCrystalCeilingSmashParams
{
	UPROPERTY()
	FVector Location;

	FStormEventCrystalCeilingSmashParams(FVector NewLocation)
	{
		Location = NewLocation;
	}
}

UCLASS(Abstract)
class UStormEventCrystalCeilingSmashEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCeilingSmash(FStormEventCeilingBreakParams Params) {}
};