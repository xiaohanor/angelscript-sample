UCLASS(Abstract)
class UCoastPoltroonEffectHandler : UHazeEffectEventHandler
{
    // The owner took damage
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTakeDamage() {}

	// The owner died
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDeath() {}

	// The owner is telegraping a shot
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTelegraph(FCoastPoltroonOnTelegraphEffectData Data) {}

	// The owner stopped telegraphing a shot
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTelegraphStop() {}

	// The owner fired a shot
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnShoot(FCoastPoltroonOnShootEffectData Data) {}

	// A target got hit by the attack
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnHit(FCoastPoltroonOnHitEffectData Data) {}
}

struct FCoastPoltroonOnTelegraphEffectData
{
	UPROPERTY(BlueprintReadOnly)
	USceneComponent Muzzle;

	FCoastPoltroonOnTelegraphEffectData(USceneComponent InMuzzle)
	{
		Muzzle = InMuzzle;
	}
}

struct FCoastPoltroonOnShootEffectData
{
	UPROPERTY(BlueprintReadOnly)
	USceneComponent Muzzle;

	FCoastPoltroonOnShootEffectData(USceneComponent InMuzzle)
	{
		Muzzle = InMuzzle;
	}
}

struct FCoastPoltroonOnHitEffectData
{
	UPROPERTY(BlueprintReadOnly)
	FHitResult HitResult;

	FCoastPoltroonOnHitEffectData(FHitResult InHitResult)
	{
		HitResult = InHitResult;
	}
}