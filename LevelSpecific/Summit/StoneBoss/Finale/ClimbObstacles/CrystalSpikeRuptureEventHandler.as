struct FOnSpikeRuptureStartedParams
{
	UPROPERTY()
	FVector Location;

	FOnSpikeRuptureStartedParams(FVector NewLocation)
	{
		Location = NewLocation;
	}
}

UCLASS(Abstract)
class UCrystalSpikeRuptureEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpikeRuptureStarted(FOnSpikeRuptureStartedParams Params) {}
};