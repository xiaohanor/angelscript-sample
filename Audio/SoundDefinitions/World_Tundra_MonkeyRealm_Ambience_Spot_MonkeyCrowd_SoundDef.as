
UCLASS(Abstract)
class UWorld_Tundra_MonkeyRealm_Ambience_Spot_MonkeyCrowd_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */


	UPROPERTY()
	ADanceShowdownManager CrowdManager;
	
	UPROPERTY()
	ACongaLineManager CongaLineManager;

	UPROPERTY()
	ATundra_SimonSaysManager SimonSaysManager;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		CrowdManager = TListedActors<ADanceShowdownManager>().Single;
		CongaLineManager = TListedActors<ACongaLineManager>().Single;
		SimonSaysManager =TListedActors<ATundra_SimonSaysManager>().Single;
	}
}