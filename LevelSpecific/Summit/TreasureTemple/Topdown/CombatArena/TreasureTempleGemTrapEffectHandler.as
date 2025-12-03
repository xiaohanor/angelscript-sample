struct FOnGemTrapImpactParams
{
	UPROPERTY()
	FVector Location;
}

struct FOnGemTrapTelegraphParams
{
	UPROPERTY()
	FVector Location;
}

UCLASS(Abstract)
class UTreasureTempleGemTrapEffectHandler : UHazeEffectEventHandler
{
	UPROPERTY()
	UDecalComponent Decal;

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGemImpact(FOnGemTrapImpactParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGemTelegraphStart(FOnGemTrapTelegraphParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGemTelegraphFinish() {}
}