
UCLASS(Abstract)
class UWorld_Island_Rift_Platform_CableWheel_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnReachedDestination(){}

	UFUNCTION(BlueprintEvent)
	void OnStartMoving(){}

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DefaultEmitter.AudioComponent.GetZoneOcclusion(true, bAutoSetRtpc = true);
	}

}