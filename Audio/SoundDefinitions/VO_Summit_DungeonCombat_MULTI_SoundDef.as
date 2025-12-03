
UCLASS(Abstract)
class UVO_Summit_DungeonCombat_MULTI_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnSpawn(){}

	UFUNCTION(BlueprintEvent)
	void AttackTelegraph(){}

	UFUNCTION(BlueprintEvent)
	void AttackStart(){}

	UFUNCTION(BlueprintEvent)
	void AttackImpact(FSmasherEventAttackImpactParams SmasherEventAttackImpactParams){}

	UFUNCTION(BlueprintEvent)
	void AttackCompleted(){}

	UFUNCTION(BlueprintEvent)
	void DigDownStart(FSmasherEventDigParams SmasherEventDigParams){}

	UFUNCTION(BlueprintEvent)
	void DigDownCompleted(FSmasherEventDigParams SmasherEventDigParams){}

	UFUNCTION(BlueprintEvent)
	void DigAppearStart(FSmasherEventDigParams SmasherEventDigParams){}

	UFUNCTION(BlueprintEvent)
	void DigAppearCompleted(FSmasherEventDigParams SmasherEventDigParams){}

	UFUNCTION(BlueprintEvent)
	void OnArmorMelted(){}

	UFUNCTION(BlueprintEvent)
	void OnArmorRestored(){}

	UFUNCTION(BlueprintEvent)
	void OnDeath(){}

	UFUNCTION(BlueprintEvent)
	void OnRollAttackKnockback(FSmasherEventOnRollAttackKnockbackParams SmasherEventOnRollAttackKnockbackParams){}

	/* END OF AUTO-GENERATED CODE */

}