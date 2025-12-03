
UCLASS(Abstract)
class UCharacter_Boss_MeltdownBoss_MeltdownBossPhaseOneLineAttack_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void AttackTriggered(){}

	UFUNCTION(BlueprintEvent)
	void HitPlayer(FMeltdownBossPhaseOneLineAttackHitPlayerParams Params){}

	UFUNCTION(BlueprintEvent)
	void AttackOver(){}

	/* END OF AUTO-GENERATED CODE */

	AMeltdownBossPhaseOne Rader;
	AMeltdownBossPhaseOneLineAttack LineAttack;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly)
	UHazeAudioEmitter PassbyEmitter;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Rader = TListedActors<AMeltdownBossPhaseOne>().GetSingle();
		LineAttack = Cast<AMeltdownBossPhaseOneLineAttack>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Rader.CurrentAttack != EMeltdownPhaseOneAttack::Line)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Rader.CurrentAttack != EMeltdownPhaseOneAttack::Line && Rader.CurrentAttack != EMeltdownPhaseOneAttack::None)
			return true;

		return false;
	}
}