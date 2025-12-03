
UCLASS(Abstract)
class UCharacter_Player_Death_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void RespawnTriggered(){}

	UFUNCTION(BlueprintEvent)
	void FinishedDying(){}

	UFUNCTION(BlueprintEvent)
	void Died(){}

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
			DamageDeathComponent.OnNewDeathEffect.AddUFunction(this, n"OnDeath");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (DamageDeathComponent != nullptr)
			DamageDeathComponent.OnNewDeathEffect.UnbindObject(this);
	}

	UFUNCTION(BlueprintEvent)
	private void OnDeath(UDeathEffect Effect, int Count)
	{

	}
}