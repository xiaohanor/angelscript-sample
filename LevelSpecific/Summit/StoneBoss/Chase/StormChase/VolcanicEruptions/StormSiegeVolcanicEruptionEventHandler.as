struct FStormOnGeyserEruptionParams
{
	UPROPERTY()
	FVector Location;

	FStormOnGeyserEruptionParams(FVector NewLocation)
	{
		Location = NewLocation;
	}
}

UCLASS(Abstract)
class UStormSiegeVolcanicEruptionEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGeyserEruption(FStormOnGeyserEruptionParams Params) {}
};