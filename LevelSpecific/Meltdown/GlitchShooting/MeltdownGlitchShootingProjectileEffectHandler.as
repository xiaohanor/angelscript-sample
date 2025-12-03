struct FMeltdownGlitchProjectileImpactEffectParams
{
	UPROPERTY()
	FVector ImpactPoint;

	UPROPERTY()
	FVector ImpactNormal;

	UPROPERTY()
	FVector ProjectileLocation;

	UPROPERTY()
	TArray<UMeltdownGlitchShootingResponseComponent> ResponseComponents;

	UPROPERTY()
	UPhysicalMaterial PhysMat;

	UPROPERTY()
	bool bHitRader = false;
}

UCLASS(Abstract)
class UMeltdownGlitchShootingProjectileEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintPure)
	AMeltdownGlitchShootingProjectile GetProjectile() const
	{
		return Cast<AMeltdownGlitchShootingProjectile>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnProjectileSpawned() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnProjectileFired() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnProjectileHit(FMeltdownGlitchProjectileImpactEffectParams Params) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnProjectileExpired() {}
};