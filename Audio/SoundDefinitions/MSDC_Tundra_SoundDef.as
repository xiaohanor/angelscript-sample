
UCLASS(Abstract)
class UMSDC_Tundra_SoundDef : UHazeMusicSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly)
	ACongaLineManager CongaLineManager;

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(CongaLineManager == nullptr)
		{
			CongaLineManager = TListedActors<ACongaLineManager>().GetSingle();
		}
	}
}