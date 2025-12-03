struct FSerpentSpikeSeedImpactParams
{
	UPROPERTY()
	FVector ImpactLoc;

	FSerpentSpikeSeedImpactParams(FVector NewImpactLoc)
	{
		ImpactLoc = NewImpactLoc;
	}
}

UCLASS(Abstract)
class USerpentSpikeSeedEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpikeImpacted(FSerpentSpikeSeedImpactParams Params) {}
};