struct FStormSiegeMetalGemAcidHitParams
{
	UPROPERTY()
	FVector Location;
}

struct FStormSiegeMetalGemSpikeHitParams
{
	UPROPERTY()
	FVector Location;
}

UCLASS(Abstract)
class UStormSiegeMetalGemEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMetalHit(FStormSiegeMetalGemAcidHitParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGemHit(FStormSiegeMetalGemSpikeHitParams Params) {}
}