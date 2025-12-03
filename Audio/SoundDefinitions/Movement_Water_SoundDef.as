
UCLASS(Abstract)
class UMovement_Water_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnSlideExitWater(FHazeAudioWaterMovementVolumeData Data){}

	UFUNCTION(BlueprintEvent)
	void OnSlideEnterWater(FHazeAudioWaterMovementVolumeData Data){}

	UFUNCTION(BlueprintEvent)
	void OnFootstepsExitWater(FHazeAudioWaterMovementVolumeData Data){}

	UFUNCTION(BlueprintEvent)
	void OnFootstepsEnterWater(FHazeAudioWaterMovementVolumeData Data){}

	/* END OF AUTO-GENERATED CODE */

	// UHazeMovementComponent MoveComp;

	// UFUNCTION(BlueprintOverride)
	// void ParentSetup()
	// {
	// 	MoveComp = UHazeMovementComponent::Get(HazeOwner);
	// }

	// UFUNCTION(BlueprintOverride)
	// bool ShouldActivate() const
	// {
	// 	// if (MoveComp.IsInAir())
	// 	// 	return false;

	// 	if (PlayerOwner.IsPlayerDead())
	// 		return false;

	// 	return true;
	// }

	// UFUNCTION(BlueprintOverride)
	// bool ShouldDeactivate() const
	// {
	// 	// if (MoveComp.IsInAir())
	// 	// 	return true;

	// 	return false;
	// }
}