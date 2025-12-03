enum EDamageEffectType
{
	Generic,
	ProjectilesSmall,
	ProjectilesLarge,
	FireSoft,
	FireImpact,
	Lava,
	ElectricitySoft,
	ElectricityImpact,
	ObjectSmall,
	ObjectLarge,
	ObjectSharp,
	LaserSoft,
	LaserHeavy,
	Poison,
	Explosion,
	Ghost,
	Eaten,
	Suffocate
}

class UDamageEffect : UObjectTickable
{
	// Whether this damage effect is currently active
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bActive = false;

	// How long this damage effect has been active for
	UPROPERTY(BlueprintReadOnly, NotEditable)
	float ActiveTimer = 0.0;

	UPROPERTY(EditDefaultsOnly)
	FSoundDefReference VOSoundDef;

	UPROPERTY(EditDefaultsOnly)
	FSoundDefReference EffectSoundDef;

	UPROPERTY(EditDefaultsOnly)
	EDamageEffectType DamageEffectType;
	
	UPROPERTY(EditDefaultsOnly, Category = "Damage Material")
	TPerPlayer<UNiagaraSystem> OverrideRecieveDamageEffect;

	/**
	 * Whether this damage effect has a maximum duration.
	 * 
	 * If not set, the damage effect must be manually Deactivate()ed.
	 */
	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly)
	bool bHasMaximumDuration = true;

	/* Duration that the damage effect will be active for before being deactivated. */
	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly, Meta = (EditCondition = "bHasMaximumDuration", EditConditionHides))
	float MaximumDuration = 1.0;

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode), DisplayName = "Activate Damage Effect")
	void BP_ActivateDamageEffect() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode), DisplayName = "Deactivate Damage Effect")
	void BP_DeactivateDamageEffect() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void DamageTaken(FPlayerDamageTakenEffectParams Params)
	{
	}

	void Activate()
	{
		if (bActive)
			return;
		bActive = true;
		ActiveTimer = 0.0;

		auto DamageAudioComp = UPlayerDeathDamageAudioComponent::GetOrCreate(GetPlayer());
		if (DamageAudioComp != nullptr)
		{
			DamageAudioComp.AttachSoundDef(this, VOSoundDef);
			DamageAudioComp.AttachSoundDef(this, EffectSoundDef);
		}

		BP_ActivateDamageEffect();
	}

	UFUNCTION(BlueprintCallable)
	void Deactivate()
	{
		if (!bActive)
			return;
		bActive = false;

		auto DamageAudioComp = UPlayerDeathDamageAudioComponent::GetOrCreate(GetPlayer());
		if (DamageAudioComp != nullptr)
		{
			DamageAudioComp.RemoveSoundDef(this, VOSoundDef);
			DamageAudioComp.RemoveSoundDef(this, EffectSoundDef);
		}

		BP_DeactivateDamageEffect();
		DestroyObject();

	}

	UFUNCTION(BlueprintPure, Category = "Damage Effect")
	AHazePlayerCharacter GetPlayer() const
	{
		return Cast<AHazePlayerCharacter>(Outer.Outer);
	}
};