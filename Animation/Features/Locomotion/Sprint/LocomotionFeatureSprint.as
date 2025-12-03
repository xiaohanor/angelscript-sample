struct FLocomotionFeatureSprintAnimData
{
	UPROPERTY(BlueprintReadOnly, Category = "Sprint")
	FHazePlaySequenceData JogStartLeft;

	UPROPERTY(BlueprintReadOnly, Category = "Sprint")
	FHazePlaySequenceData JogStartRight;

	UPROPERTY(Category = "Sprint")
    FHazePlayBlendSpaceData SprintBS;

	UPROPERTY(Category = "Sprint")
    FHazePlaySequenceData StopLeft;

	UPROPERTY(Category = "Sprint")
    FHazePlaySequenceData StopRight;

	UPROPERTY(Category = "Sprint")
    FHazePlaySequenceData SlowdownStopLeft;

	UPROPERTY(Category = "Sprint")
    FHazePlaySequenceData SlowdownStopRight;

	UPROPERTY(Category = "Sprint")
    FHazePlaySequenceData StopLeftToJog;

	UPROPERTY(Category = "Sprint")
    FHazePlaySequenceData StopRightToJog;

	UPROPERTY(Category = "Sprint")
    FHazePlaySequenceData SlowdownLeftToJog;

	UPROPERTY(Category = "Sprint")
    FHazePlaySequenceData SlowdownRightToJog;
	
	
}

class ULocomotionFeatureSprint : UHazeLocomotionFeatureBase
{
	default Tag = n"Sprint";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSprintAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
