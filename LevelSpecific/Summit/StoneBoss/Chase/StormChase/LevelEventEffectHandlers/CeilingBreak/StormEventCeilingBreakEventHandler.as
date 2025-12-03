struct FStormEventCeilingBreakParams
{
	UPROPERTY()
	FVector Location;

	FStormEventCeilingBreakParams(FVector NewLocation)
	{
		Location = NewLocation;
	}
}

UCLASS(Abstract)
class UStormEventCeilingBreakEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCeilingBreak(FStormEventCeilingBreakParams Params) {}
};