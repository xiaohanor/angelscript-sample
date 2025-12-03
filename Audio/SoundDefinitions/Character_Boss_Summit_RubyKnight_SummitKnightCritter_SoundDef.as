
UCLASS(Abstract)
class UCharacter_Boss_Summit_RubyKnight_SummitKnightCritter_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnStartAttack(){}

	UFUNCTION(BlueprintEvent)
	void OnKillPlayer(){}

	UFUNCTION(BlueprintEvent)
	void OnLatchOnToPlayer(){}

	UFUNCTION(BlueprintEvent)
	void OnDeath(){}

	UFUNCTION(BlueprintEvent)
	void OnPlayerDamage(FSummitKnightCritterDamagePlayerParams Params){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly)
	AAISummitKnightCritter Critter;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Critter = Cast<AAISummitKnightCritter>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Critter.OnAIDie.AddUFunction(this, n"OnDeath");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Critter.OnAIDie.Unbind(this, n"OnDeath");
	}

}