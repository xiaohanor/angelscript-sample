
UCLASS(Abstract)
class UCharacter_Boss_Meltdown_Boss_PhaseThreeDecimator_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnDisappear(){}

	UFUNCTION(BlueprintEvent)
	void HitByPlayerAttack(FMeltdownGlitchImpact GlitchImpact){}

	UFUNCTION(BlueprintEvent)
	void DestroyedByPlayerAttack(){}

	UFUNCTION(BlueprintEvent)
	void SpawnSpear(FMeltdownPhaseThreeDecimatorSpearAttackSpawnParams Params){}

	UFUNCTION(BlueprintEvent)
	void SpawnSpikeBomb(){}

	UFUNCTION(BlueprintEvent)
	void PreSpawnSpears(){}

	/* END OF AUTO-GENERATED CODE */

	AMeltdownPhaseThreeDecimator Decimator;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Decimator = Cast<AMeltdownPhaseThreeDecimator>(HazeOwner);
	}
}