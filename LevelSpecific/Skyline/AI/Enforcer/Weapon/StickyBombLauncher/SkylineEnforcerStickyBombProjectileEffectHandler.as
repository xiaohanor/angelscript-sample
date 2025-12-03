UCLASS(Abstract)
class USkylineEnforcerStickyBombProjectileEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnPrime() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnLaunch() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnImpact(FSkylineEnforcerStickyBombImpactData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnExplode(FSkylineEnforcerStickyBombImpactData Data) {}
}

struct FSkylineEnforcerStickyBombImpactData
{
	FHitResult HitResult;
}