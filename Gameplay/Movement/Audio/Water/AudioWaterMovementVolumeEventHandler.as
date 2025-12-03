
struct FHazeAudioWaterMovementVolumeData
{
	UPROPERTY()
	AAudioWaterMovementVolume WaterMovementVolume;

	FHazeAudioWaterMovementVolumeData(AAudioWaterMovementVolume InVolume) 
	{
		WaterMovementVolume = InVolume;
	}
}

UCLASS(Abstract)
class UAudioWaterMovementVolumeEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFootstepsEnterWater(FHazeAudioWaterMovementVolumeData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFootstepsExitWater(FHazeAudioWaterMovementVolumeData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSlideEnterWater(FHazeAudioWaterMovementVolumeData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSlideExitWater(FHazeAudioWaterMovementVolumeData Data) {}
};