
UCLASS(Abstract)
class UVO_Player_DamageDefault_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void DamageTaken(FPlayerDamageTakenEffectParams PlayerDamageTakenEffectParams){}

	UFUNCTION(BlueprintEvent)
	void Healed(FPlayerHealedEffectParams PlayerHealedEffectParams){}

	UFUNCTION(BlueprintEvent)
	void HealthUpdated(FPlayerHealthUpdatedParams PlayerHealthUpdatedParams){}

	UFUNCTION(BlueprintEvent)
	void PlayerDied(FPlayerDeathDamageParams PlayerDeathDamageParams){}

	UFUNCTION(BlueprintEvent)
	void PlayerRevived(){}

	UFUNCTION(BlueprintEvent)
	void HealthRegenerated(){}

	UFUNCTION(BlueprintEvent)
	void AvoidedDamageByInvulnerable(FPlayerDamageTakenEffectParams PlayerDamageTakenEffectParams){}

	UFUNCTION(BlueprintEvent)
	void RemovePlayerOverlayMaterial(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly)
	UPlayerEffortAudioComponent EffortComp;

	UPROPERTY(BlueprintReadOnly)
	UPlayerHealthComponent HealthComp;

	UPROPERTY(NotVisible)
	UVODamageDeathSettings Settings;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Settings != nullptr && !Settings.bDamageEnabled)
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Settings != nullptr && !Settings.bDamageEnabled)
			return true;
			
		return false;
	}


	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		EffortComp = UPlayerEffortAudioComponent::Get(HazeOwner);
		HealthComp = UPlayerHealthComponent::Get(HazeOwner);
		Settings = UVODamageDeathSettings::GetSettings(HazeOwner);
	}

	UFUNCTION(BlueprintPure)
	float GetHealth() const
	{
		if (HealthComp != nullptr)
			return HealthComp.Health.CurrentHealth;

		return 0;
	}
}