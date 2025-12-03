struct FLocomotionFeatureForceFieldSpinnerBatteryAnimData
{
	UPROPERTY(Category = "ForceFieldSpinnerBattery")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "ForceFieldSpinnerBattery")
	FHazePlayBlendSpaceData Exit;

	UPROPERTY(Category = "ForceFieldSpinnerBattery")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "ForceFieldSpinnerBattery")
	FHazePlaySequenceData MhExtended;

	UPROPERTY(Category = "ForceFieldSpinnerBattery")
	FHazePlaySequenceData Pull;

	UPROPERTY(Category = "ForceFieldSpinnerBattery")
	FHazePlaySequenceData Push;
}

class ULocomotionFeatureForceFieldSpinnerBattery : UHazeLocomotionFeatureBase
{
	default Tag = n"ForceFieldSpinnerBattery";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureForceFieldSpinnerBatteryAnimData AnimData;
}
