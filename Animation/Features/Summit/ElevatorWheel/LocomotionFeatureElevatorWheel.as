struct FLocomotionFeatureElevatorWheelAnimData
{
	UPROPERTY(Category = "ElevatorWheel")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "ElevatorWheel")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "ElevatorWheel")
	FHazePlaySequenceData Spin;

	UPROPERTY(Category = "ElevatorWheel")
	FHazePlaySequenceData Exit;
}

class ULocomotionFeatureElevatorWheel : UHazeLocomotionFeatureBase
{
	default Tag = n"ElevatorWheel";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureElevatorWheelAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
