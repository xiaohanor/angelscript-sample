struct FSummitBreakingGapParams
{
	UPROPERTY()
	FVector Location;

	FSummitBreakingGapParams(FVector NewLocation)
	{
		Location = NewLocation;
	}
}

UCLASS(Abstract)
class USummitBreakingGapEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartGapBreaking(FSummitBreakingGapParams Params) {}
};