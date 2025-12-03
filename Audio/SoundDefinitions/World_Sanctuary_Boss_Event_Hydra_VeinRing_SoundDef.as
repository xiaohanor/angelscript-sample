
UCLASS(Abstract)
class UWorld_Sanctuary_Boss_Event_Hydra_VeinRing_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditAnywhere)
	ASanctuaryBossHeartBeatManager Manager;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Manager = TListedActors<ASanctuaryBossHeartBeatManager>().Single;
	}

}