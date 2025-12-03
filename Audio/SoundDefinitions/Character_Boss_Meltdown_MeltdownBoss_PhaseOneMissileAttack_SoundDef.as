
UCLASS(Abstract)
class UCharacter_Boss_Meltdown_MeltdownBoss_PhaseOneMissileAttack_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void SpawnMissile(FMeltdownBossPhaseOneMissileSpawnParams SpawnParams){}

	UFUNCTION(BlueprintEvent)
	void ThrowMissile(FMeltdownBossPhaseOneMissileThrowParams ThrowParams){}

	UFUNCTION(BlueprintEvent)
	void MissileHit(FMeltdownBossPhaseOneMissileHitParams HitParams){}

	/* END OF AUTO-GENERATED CODE */

	AMeltdownBossPhaseOneMissileAttack AttackActor;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		AttackActor = Cast<AMeltdownBossPhaseOneMissileAttack>(HazeOwner);
	}

	UFUNCTION(BlueprintPure)
	float IncomingAlpha()
	{
		return AttackActor.IncomingAlpha();
	}
	

}