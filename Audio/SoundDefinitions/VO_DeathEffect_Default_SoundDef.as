
UCLASS(Abstract)
class UVO_DeathEffect_Default_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void Death_PlayCameraShakeAndRumble(){}

	UFUNCTION(BlueprintEvent)
	void Death_DeathAndRespawnCycleCompleted(){}

	UFUNCTION(BlueprintEvent)
	void Death_RespawnTriggered(){}

	UFUNCTION(BlueprintEvent)
	void Death_RespawnStarted(){}

	UFUNCTION(BlueprintEvent)
	void Death_FinishedDying(){}

	UFUNCTION(BlueprintEvent)
	void Death_Died(){}

	UFUNCTION(BlueprintEvent)
	void Death_OnRespawnPulseMash(){}

	UFUNCTION(BlueprintEvent)
	void PlayerDamage_DamageTaken(FPlayerDamageTakenEffectParams PlayerDamageTakenEffectParams){}

	UFUNCTION(BlueprintEvent)
	void PlayerDamage_Healed(FPlayerHealedEffectParams PlayerHealedEffectParams){}

	UFUNCTION(BlueprintEvent)
	void PlayerDamage_HealthUpdated(FPlayerHealthUpdatedParams PlayerHealthUpdatedParams){}

	UFUNCTION(BlueprintEvent)
	void PlayerDamage_PlayerDied(FPlayerDeathDamageParams PlayerDeathDamageParams){}

	UFUNCTION(BlueprintEvent)
	void PlayerDamage_PlayerRevived(){}

	UFUNCTION(BlueprintEvent)
	void PlayerDamage_HealthRegenerated(){}

	UFUNCTION(BlueprintEvent)
	void PlayerDamage_AvoidedDamageByInvulnerable(FPlayerDamageTakenEffectParams PlayerDamageTakenEffectParams){}

	UFUNCTION(BlueprintEvent)
	void PlayerDamage_RemovePlayerOverlayMaterial(){}

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
		if (Settings != nullptr && !Settings.bDeathEnabled)
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Settings != nullptr && !Settings.bDeathEnabled)
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