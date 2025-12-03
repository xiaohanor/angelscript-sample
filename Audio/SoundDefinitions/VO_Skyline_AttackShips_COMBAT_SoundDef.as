
UCLASS(Abstract)
class UVO_Skyline_AttackShips_COMBAT_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnShieldDamage(FSkylineAttackShipShieldEventData SkylineAttackShipShieldEventData){}

	UFUNCTION(BlueprintEvent)
	void OnStartAimLaser(FSkylineAttackShipAttackEventData SkylineAttackShipAttackEventData){}

	UFUNCTION(BlueprintEvent)
	void OnStopAimLaser(FSkylineAttackShipAttackEventData SkylineAttackShipAttackEventData){}

	UFUNCTION(BlueprintEvent)
	void OnFireMissiles(FSkylineAttackShipAttackEventData SkylineAttackShipAttackEventData){}

	UFUNCTION(BlueprintEvent)
	void OnWeakPointHit(){}

	UFUNCTION(BlueprintEvent)
	void OnCrash(){}

	/* END OF AUTO-GENERATED CODE */

}