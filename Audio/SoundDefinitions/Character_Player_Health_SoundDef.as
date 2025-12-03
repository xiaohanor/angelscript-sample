
UCLASS(Abstract)
class UCharacter_Player_Health_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void RemovePlayerOverlayMaterial(){}

	UFUNCTION(BlueprintEvent)
	void HealthRegenerated(){}

	UFUNCTION(BlueprintEvent)
	void PlayerRevived(){}

	UFUNCTION(BlueprintEvent)
	void PlayerDied(FPlayerDeathDamageParams Params){}

	UFUNCTION(BlueprintEvent)
	void HealthUpdated(FPlayerHealthUpdatedParams Params){}

	UFUNCTION(BlueprintEvent)
	void DamageTaken(FPlayerDamageTakenEffectParams Params){}

	/* END OF AUTO-GENERATED CODE */

	private UPlayerDeathDamageAudioComponent DamageDeathComponent;
	private UPlayerHealthComponent HealthComponent;
	private bool bTrackingDamage = false;
	private TArray<FSoundDefReference> AddedSoundDefs;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		// Must be attached to the player
		devCheck(PlayerOwner != nullptr);
		DamageDeathComponent = UPlayerDeathDamageAudioComponent::GetOrCreate(PlayerOwner);
		HealthComponent = UPlayerHealthComponent::Get(PlayerOwner);
	}

	// From this event we need to track if the damage effect is valid, does it have a sounddef, and when will the invulnerablility turn off.
	UFUNCTION()
	void AvoidedDamageByInvulnerable(FPlayerDamageTakenEffectParams Params)
	{
		if (!ValidDamage(Params))
			return;

		if (DamageDeathComponent.AttachInvulnerableSoundDef(this, Params.EffectSoundDef))
		{
			AddedSoundDefs.Add(Params.EffectSoundDef);
			#if TEST
			DebugPrintString(f"Attaching {Params.EffectSoundDef.SoundDef}} due to invulnerbility", true, true, Duration = 5);
			#endif
		}
		bTrackingDamage = true;
	}

	// What we want to know is does the current damage dealt matter to us?
	bool ValidDamage(const FPlayerDamageTakenEffectParams& Params) const 
	{
		if (!HealthComponent.CanDie())
			return false;

		if (!Params.EffectSoundDef.IsValid())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if (!bTrackingDamage)
			return;

		if (HealthComponent.DamageInvulnerabilities.Num() == 0)
		{
			for (auto SoundDefRef: AddedSoundDefs)
			{
				DamageDeathComponent.RemoveInvulnerableSoundDef(this, SoundDefRef);
			}
			AddedSoundDefs.Reset();

			bTrackingDamage = false;
		}
	}
}