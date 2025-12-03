
UCLASS(Abstract)
class UCharacter_Boss_Meltdown_MeltdownBossPhaseTwoBat_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void SpaceBatPhaseStart(){}

	UFUNCTION(BlueprintEvent)
	void SpaceBatPhaseEnd(){}

	UFUNCTION(BlueprintEvent)
	void SpaceBatSwingLeft(){}

	UFUNCTION(BlueprintEvent)
	void SpaceBatSwingRight(){}

	/* END OF AUTO-GENERATED CODE */

	AMeltdownBossPhaseTwo Rader;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Rader = Cast<AMeltdownBossPhaseTwo>(HazeOwner);
		DefaultEmitter.AttachEmitterTo(Rader.Bat.Root);
	}

}