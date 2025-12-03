
UCLASS(Abstract)
class UWorld_Skyline_Highway_Platform_TraversalVehicle_Car_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		DefaultEmitter.AudioComponent.GetZoneOcclusion(true, bAutoSetRtpc = true);
	}

}