UCLASS(Abstract)
class UCoastWaterJetEffectHandler : UHazeEffectEventHandler
{
    // The owner took damage
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTakeDamage() {}

	// The owner died
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDeath() {}

	// The owner is telegraping a shot
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTelegraph(FCoastWaterJetOnTelegraphEffectData Data) {}

	// The owner stopped telegraphing a shot
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTelegraphStop() {}

	// The owner fired a shot
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnAttack(FCoastWaterJetOnAttackEffectData Data) {}

	// Something got hit by the attack
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnAttackImpact(FCoastWaterJetOnAttackImpactEffectData Data) {}


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

struct FCoastWaterJetOnTelegraphEffectData
{
	UPROPERTY(BlueprintReadOnly)
	USceneComponent Muzzle;

	FCoastWaterJetOnTelegraphEffectData(USceneComponent InMuzzle)
	{
		Muzzle = InMuzzle;
	}
}

struct FCoastWaterJetOnAttackEffectData
{
	UPROPERTY(BlueprintReadOnly)
	USceneComponent Muzzle;

	FCoastWaterJetOnAttackEffectData(USceneComponent InMuzzle)
	{
		Muzzle = InMuzzle;
	}
}

struct FCoastWaterJetOnAttackImpactEffectData
{
	UPROPERTY(BlueprintReadOnly)
	FHitResult HitResult;

	FCoastWaterJetOnAttackImpactEffectData(FHitResult InHitResult)
	{
		HitResult = InHitResult;
	}
}


