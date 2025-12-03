
UCLASS(Abstract)
class UWorld_Skyline_Highway_Interactable_Rotating_Crusher_SoundDef : USpot_Tracking_SoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnDoorOpen(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadWrite)
	float DoorIsOpenValue = 0.0;

	UFUNCTION(BlueprintPure)
	float GetZoneOcclusion()
	{
		return GetZoneOcclusionValue(DefaultEmitter, true, SpotComponent.LinkedZone, bAutoSetRtpc = false);		
	}

}