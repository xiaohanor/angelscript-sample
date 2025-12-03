struct FIslandShieldotronProjectileOnImpactData
{
	UPROPERTY()
	FHitResult HitResult;
}

UCLASS(Abstract)
class UIslandShieldotronProjectileEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnPrime() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnLaunch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnImpact(FBasicAiProjectileOnImpactData Params) {}
}

