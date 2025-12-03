
UCLASS(Abstract)
class UCharacter_Boss_Meltdown_MeltdownBossTrident_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void TridentPhaseStart(){}

	UFUNCTION(BlueprintEvent)
	void TridentPhaseEnd(){}

	UFUNCTION(BlueprintEvent)
	void SharkSummonStart(){}

	UFUNCTION(BlueprintEvent)
	void SharkSummonEnd(){}

	UFUNCTION(BlueprintEvent)
	void TridentSlamStart(){}

	/* END OF AUTO-GENERATED CODE */

	AMeltdownBossPhaseTwo Rader;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Rader = Cast<AMeltdownBossPhaseTwo>(HazeOwner);
		DefaultEmitter.AttachEmitterTo(UStaticMeshComponent::Get(Rader.Trident));
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		TargetActor = HazeOwner;
		bUseAttach = false;
		return true;
	}

}