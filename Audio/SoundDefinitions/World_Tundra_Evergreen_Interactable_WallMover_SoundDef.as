
UCLASS(Abstract)
class UWorld_Tundra_Evergreen_Interactable_WallMover_SoundDef : USpot_Tracking_SoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION(BlueprintPure)
	float32 CameraIsInWater()
	{

		float32 IsInWaterValue = -1;
            AudioComponent::GetRTPC(Game::GetMio().PlayerAudioComponent.GetAnyEmitter(), FHazeAudioID("Rtpc_Shared_Camera_InWater"), IsInWaterValue);
            return IsInWaterValue;

	}

}