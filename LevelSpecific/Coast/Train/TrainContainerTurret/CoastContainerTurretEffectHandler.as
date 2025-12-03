UCLASS(Abstract)
class UCoastContainerTurretEffectHandler : UHazeEffectEventHandler
{
    // The owner took damage
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTakeDamage() {}

	// The owner died
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDeath() {}

	// The owner unspawned
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnUnspawn() {}

	// The owner respawned
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnRespawn() {}

	// The owner is telegraping a shot
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTelegraph(FCoastContainerTurretOnTelegraphEffectData Data) {}

	// The owner stopped telegraphing a shot
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTelegraphStop() {}

	// The owner fired a shot
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnShoot(FCoastContainerTurretOnShootEffectData Data) {}

	// A target got hit by the turret shot
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnHit(FCoastContainerTurretOnHitEffectData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnFallStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnFallEnd() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnLand() {}
}

struct FCoastContainerTurretOnTelegraphEffectData
{
	UPROPERTY(BlueprintReadOnly)
	USceneComponent Muzzle;

	FCoastContainerTurretOnTelegraphEffectData(USceneComponent InMuzzle)
	{
		Muzzle = InMuzzle;
	}
}

struct FCoastContainerTurretOnShootEffectData
{
	UPROPERTY(BlueprintReadOnly)
	USceneComponent Muzzle;

	FCoastContainerTurretOnShootEffectData(USceneComponent InMuzzle)
	{
		Muzzle = InMuzzle;
	}
}

struct FCoastContainerTurretOnHitEffectData
{
	UPROPERTY(BlueprintReadOnly)
	FHitResult HitResult;

	FCoastContainerTurretOnHitEffectData(FHitResult InHitResult)
	{
		HitResult = InHitResult;
	}
}