UCLASS(Abstract)
class UBasicAIProjectileEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnPrime() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnLaunch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnImpact(FBasicAiProjectileOnImpactData Data) {}
}

struct FBasicAiProjectileOnImpactData
{
	UPROPERTY()
	FHitResult HitResult;
}