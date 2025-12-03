UCLASS(Abstract)
class USkylineHighwayBossVehicleGunProjectileEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTelegraph(FSkylineHighwayBossVehicleGunProjectileEffectHandlerOnTelegraphData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnImpact(FSkylineHighwayBossVehicleGunProjectileEffectHandlerOnImpactData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnExpire() {}
}

struct FSkylineHighwayBossVehicleGunProjectileEffectHandlerOnTelegraphData
{
	UPROPERTY()
	FVector TargetLocation;
}

struct FSkylineHighwayBossVehicleGunProjectileEffectHandlerOnImpactData
{
	UPROPERTY()
	FHitResult Hit;

	FSkylineHighwayBossVehicleGunProjectileEffectHandlerOnImpactData(FHitResult _Hit)
	{
		Hit = _Hit;
	}
}