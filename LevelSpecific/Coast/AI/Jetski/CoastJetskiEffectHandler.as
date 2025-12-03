UCLASS(Abstract)
class UCoastJetskiEffectHandler : UHazeEffectEventHandler
{
    // The owner took damage
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTakeDamage() {}

	// The owner died
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDeath() {}

	// The owner is telegraping a shot
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTelegraph(FCoastJetskiOnTelegraphEffectData Data) {}

	// The owner stopped telegraphing a shot
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTelegraphStop() {}

	// The owner fired a shot
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnAttack(FCoastJetskiOnAttackEffectData Data) {}

	// Something got hit by the attack
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnAttackImpact(FCoastJetskiOnAttackImpactEffectData Data) {}


	UFUNCTION(BlueprintPure)
	bool IsPastWidgetCooldown(AHazePlayerCharacter Player) const
	{
		UGentlemanComponent GentlemanComp = UGentlemanComponent::GetOrCreate(Player);
		if (GentlemanComp.CanClaimToken(n"AddHurtWdiget", this))
			return true;
		return false;
	}

	UFUNCTION()
	void SetWidgetCooldown(AHazePlayerCharacter Player, float Cooldown)
	{
		UGentlemanComponent GentlemanComp = UGentlemanComponent::GetOrCreate(Player);
		GentlemanComp.ClaimToken(n"AddHurtWdiget", this);
		GentlemanComp.ReleaseToken(n"AddHurtWdiget", this, Cooldown);
	}
}

struct FCoastJetskiOnTelegraphEffectData
{
	UPROPERTY(BlueprintReadOnly)
	USceneComponent Muzzle;

	FCoastJetskiOnTelegraphEffectData(USceneComponent InMuzzle)
	{
		Muzzle = InMuzzle;
	}
}

struct FCoastJetskiOnAttackEffectData
{
	UPROPERTY(BlueprintReadOnly)
	USceneComponent Muzzle;

	FCoastJetskiOnAttackEffectData(USceneComponent InMuzzle)
	{
		Muzzle = InMuzzle;
	}
}

struct FCoastJetskiOnAttackImpactEffectData
{
	UPROPERTY(BlueprintReadOnly)
	FHitResult HitResult;

	FCoastJetskiOnAttackImpactEffectData(FHitResult InHitResult)
	{
		HitResult = InHitResult;
	}
}


