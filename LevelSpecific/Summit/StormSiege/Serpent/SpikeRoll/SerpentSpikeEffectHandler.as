struct FSerpentSpikeImpactParams
{
	UPROPERTY()
	FVector ImpactLoc;

	FSerpentSpikeImpactParams(FVector NewImpactLoc)
	{
		ImpactLoc = NewImpactLoc;
	}
}

UCLASS(Abstract)
class USerpentSpikeEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartGrowing(FSerpentSpikeImpactParams Params) 
	{
		Print("Hello");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FSerpentSpikeImpactParams Params) {}
};