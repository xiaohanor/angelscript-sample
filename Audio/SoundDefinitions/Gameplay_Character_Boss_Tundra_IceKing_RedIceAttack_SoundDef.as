
UCLASS(Abstract)
class UGameplay_Character_Boss_Tundra_IceKing_RedIceAttack_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnSpawnRedIceAttack(FTundraBossRedIceAttackData Data){}

	/* END OF AUTO-GENERATED CODE */

	ATundraBoss IceKing;

	UPROPERTY(BlueprintReadWrite)
	FHazeAudioEmitterRotationPool EmitterPool;
	
	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		IceKing = Cast<ATundraBoss>(HazeOwner);
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