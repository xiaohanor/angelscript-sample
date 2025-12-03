
UCLASS(Abstract)
class UCharacter_Boss_Meltdown_MeltdownBoss_PhaseOneCylinderAttack_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void StartRotatingCylinder(){}

	UFUNCTION(BlueprintEvent)
	void FinishRotatingCylinder(){}

	UFUNCTION(BlueprintEvent)
	void FinishCylinderAttack(){}

	/* END OF AUTO-GENERATED CODE */

	AMeltdownBossPhaseOne Rader;

	TArray<FMeltdownPhaseOneCylinderAttackDangerZone> DangerZones;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Rader = Cast<AMeltdownBossPhaseOne>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Rader.CurrentAttack != EMeltdownPhaseOneAttack::Cylinder)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Rader.CurrentAttack != EMeltdownPhaseOneAttack::Cylinder && Rader.CurrentAttack != EMeltdownPhaseOneAttack::None)
			return true;

		return false;
	}
}