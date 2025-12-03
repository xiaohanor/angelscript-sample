struct FDarkCaveMetalSlowProjectileParams
{
	UPROPERTY()
	FVector ImpactLocation;

	UPROPERTY()
	FRotator ImpactRotation;
}

UCLASS(Abstract)
class USummitDarkCaveMetalSlowProjectileEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Impact(FDarkCaveMetalSlowProjectileParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Melted(FDarkCaveMetalSlowProjectileParams Params) {}
};