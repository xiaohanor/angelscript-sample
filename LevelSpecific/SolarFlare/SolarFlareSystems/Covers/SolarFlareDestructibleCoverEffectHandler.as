struct FOnSolarFlareDestructibleCoverActivatedParams
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	int Index;
}

struct FOnSolarFlareDestructibleCoverGeneralParams
{
	UPROPERTY()
	FVector Location;
}

UCLASS(Abstract)
class USolarFlareDestructibleCoverEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDestructionImpact(FOnSolarFlareDestructibleCoverActivatedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCoverPermaDestroyed(FOnSolarFlareDestructibleCoverGeneralParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCoverImpacted(FOnSolarFlareDestructibleCoverGeneralParams Params) {}
}