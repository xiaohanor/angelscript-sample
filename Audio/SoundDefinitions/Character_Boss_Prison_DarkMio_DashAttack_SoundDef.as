
UCLASS(Abstract)
class UCharacter_Boss_Prison_DarkMio_DashAttack_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void DashSlashAttackStarted(){}

	UFUNCTION(BlueprintEvent)
	void DashSlashTelegraph(){}

	/* END OF AUTO-GENERATED CODE */

	APrisonBoss DarkMio;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		DarkMio = Cast<APrisonBoss>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return DarkMio.CurrentAttackType == EPrisonBossAttackType::DashSlash;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return DarkMio.CurrentAttackType != EPrisonBossAttackType::DashSlash;
	}

}