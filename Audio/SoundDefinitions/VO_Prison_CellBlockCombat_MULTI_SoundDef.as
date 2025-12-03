
UCLASS(Abstract)
class UVO_Prison_CellBlockCombat_MULTI_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void PrisonGuardBot_OnHitReactionStop(){}

	UFUNCTION(BlueprintEvent)
	void PrisonGuardBot_OnHitReactionStart(){}

	UFUNCTION(BlueprintEvent)
	void PrisonGuardBot_OnShoot(FPrisonGuardBotShootParams PrisonGuardBotShootParams){}

	UFUNCTION(BlueprintEvent)
	void PrisonGuardBot_OnZapStop(FPrisonGuardBotZapParams PrisonGuardBotZapParams){}

	UFUNCTION(BlueprintEvent)
	void PrisonGuardBot_OnZapStart(FPrisonGuardBotZapParams PrisonGuardBotZapParams){}

	UFUNCTION(BlueprintEvent)
	void PrisonGuardBot_OnExplode(){}

	UFUNCTION(BlueprintEvent)
	void PrisonGuardBot_OnChargeEnd(){}

	UFUNCTION(BlueprintEvent)
	void PrisonGuardBot_OnChargeStart(){}

	UFUNCTION(BlueprintEvent)
	void PrisonGuardBot_OnTelegraphCharge(){}

	UFUNCTION(BlueprintEvent)
	void PrisonGuard_OnStunnedStop(){}

	UFUNCTION(BlueprintEvent)
	void PrisonGuard_OnStunnedStart(FPrisonGuardDamageParams PrisonGuardDamageParams){}

	UFUNCTION(BlueprintEvent)
	void PrisonGuard_OnAttackStop(FPrisonGuardAttackParams PrisonGuardAttackParams){}

	UFUNCTION(BlueprintEvent)
	void PrisonGuard_OnAttackStart(FPrisonGuardAttackParams PrisonGuardAttackParams){}

	UFUNCTION(BlueprintEvent)
	void PrisonGuard_OnDeath(FPrisonGuardDamageParams PrisonGuardDamageParams){}

	UFUNCTION(BlueprintEvent)
	void PrisonGuard_OnRespawn(){}

	UFUNCTION(BlueprintEvent)
	void PrisonGuardBot_OnMagneticBurstStunnedEnd(){}

	UFUNCTION(BlueprintEvent)
	void PrisonGuardBot_OnMagneticBurstStunnedStart(){}

	UFUNCTION(BlueprintEvent)
	void CellBlockGuardSpawnerCore_ShootCore(FCellBlockGuardSpawnerShootCoreImpactData CellBlockGuardSpawnerShootCoreImpactData){}

	UFUNCTION(BlueprintEvent)
	void CellBlockGuardSpawnerCore_Explode(){}

	UFUNCTION(BlueprintEvent)
	void PrisonGuardBot_OnShootAtBadTarget(){}

	/* END OF AUTO-GENERATED CODE */
}