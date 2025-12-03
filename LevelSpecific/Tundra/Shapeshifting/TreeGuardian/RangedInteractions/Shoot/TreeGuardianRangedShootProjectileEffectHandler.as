struct FTreeGuardianRangedShootProjectileImpactParams
{
	UPROPERTY()
	FVector ProjectileLocation;
}

struct FTreeGuardianRangedShootProjectileDespawnParams
{
	UPROPERTY()
	FVector ProjectileLocation;
}

struct FTreeGuardianRangedShootProjectileGrabbedParams
{
	UPROPERTY()
	bool bHasTarget = false;
}

UCLASS(Abstract)
class UTundraTreeGuardianRangedShootProjectileVFXHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunched() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBreakWaterSurface() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGrabbedByTreeGuardian(FTreeGuardianRangedShootProjectileGrabbedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThrownByTreeGuardian() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FTreeGuardianRangedShootProjectileImpactParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFailDespawn(FTreeGuardianRangedShootProjectileDespawnParams Params) {}
}