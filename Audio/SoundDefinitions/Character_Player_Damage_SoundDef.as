
UCLASS(Abstract)
class UCharacter_Player_Damage_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void HealthRegenerated(){}

	UFUNCTION(BlueprintEvent)
	void PlayerRevived(){}

	UFUNCTION(BlueprintEvent)
	void DamageTaken(FPlayerDamageTakenEffectParams Params){}

	UFUNCTION(BlueprintEvent)
	void PlayerDied(FPlayerDeathDamageParams Params){}

	UFUNCTION(BlueprintEvent)
	void RemovePlayerOverlayMaterial(){}

	UFUNCTION(BlueprintEvent)
	void HealthUpdated(FPlayerHealthUpdatedParams Params){}

	UFUNCTION(BlueprintEvent)
	void Healed(FPlayerHealedEffectParams Params){}

	/* END OF AUTO-GENERATED CODE */

	UPlayerDeathDamageAudioComponent DamageDeathComponent;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		// This component will attach the SD, if it doesn't exist someting is haze.
		DamageDeathComponent = UPlayerDeathDamageAudioComponent::Get(HazeOwner);
		devCheck(DamageDeathComponent != nullptr);

	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (DamageDeathComponent != nullptr)
			DamageDeathComponent.OnNewDamageEffect.AddUFunction(this, n"OnDamage");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (DamageDeathComponent != nullptr)
			DamageDeathComponent.OnNewDamageEffect.UnbindObject(this);
	}

	UFUNCTION(BlueprintEvent)
	private void OnDamage(UDamageEffect Effect, int Count)
	{

	}
}