
UCLASS(Abstract)
class UVO_Skyline_DaClub_Subway_Shared_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void DestroyBeam(FGravityWhipBeamData GravityWhipBeamData){}

	UFUNCTION(BlueprintEvent)
	void WhipAirGrabEnd(){}

	UFUNCTION(BlueprintEvent)
	void WhipAirGrabStart(){}

	UFUNCTION(BlueprintEvent)
	void TargetThrown(FGravityWhipReleaseData GravityWhipReleaseData){}

	UFUNCTION(BlueprintEvent)
	void TargetPreThrown(FGravityWhipReleaseData GravityWhipReleaseData){}

	UFUNCTION(BlueprintEvent)
	void TargetReleased(FGravityWhipReleaseData GravityWhipReleaseData){}

	UFUNCTION(BlueprintEvent)
	void TargetGrabbed(FGravityWhipGrabData GravityWhipGrabData){}

	UFUNCTION(BlueprintEvent)
	void TargetStartGrab(FGravityWhipGrabData GravityWhipGrabData){}

	UFUNCTION(BlueprintEvent)
	void WhipFinishedRetracting(){}

	UFUNCTION(BlueprintEvent)
	void WhipStartRetracting(){}

	UFUNCTION(BlueprintEvent)
	void WhipLaunched(){}

	/* END OF AUTO-GENERATED CODE */

}