struct FOnSummitGemSpikeDestroyedParams
{
	UPROPERTY()
	float Scale;

	UPROPERTY()
	FVector Location;

	UPROPERTY()
	FRotator Rotation;
}

struct FOnSummitGemSpikeGrowParams
{
	UPROPERTY()
	FVector Location;

	FOnSummitGemSpikeGrowParams(FVector NewLocation)
	{
		Location = NewLocation;
	}
}

UCLASS(Abstract)
class USummitGemSpikeEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DestroyGem(FOnSummitGemSpikeDestroyedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GrowGem(FOnSummitGemSpikeGrowParams Params) {}
}