struct FLocomotionFeatureSpaceTouchScreenAnimData
{
	UPROPERTY(Category = "Grounded")
	FHazePlaySequenceData GroundedEnter;

	UPROPERTY(Category = "Grounded")
	FHazePlaySequenceData GroundedMH;

	UPROPERTY(Category = "Grounded")
	FHazePlaySequenceData GroundedSwipeLeft;

	UPROPERTY(Category = "Grounded")
	FHazePlaySequenceData GroundedSwipeRight;

	UPROPERTY(Category = "Grounded")
	FHazePlaySequenceData GroundedButtonPush;

	UPROPERTY(Category = "Grounded")
	FHazePlaySequenceData GroundedExit;

	UPROPERTY(Category = "ZeroG")
	FHazePlaySequenceData ZeroGEnter;

	UPROPERTY(Category = "ZeroG")
	FHazePlaySequenceData ZeroGMH;

	UPROPERTY(Category = "ZeroG")
	FHazePlaySequenceData ZeroGSwipeLeft;

	UPROPERTY(Category = "ZeroG")
	FHazePlaySequenceData ZeroGSwipeRight;

	UPROPERTY(Category = "ZeroG")
	FHazePlaySequenceData ZeroGButtonPush;

	UPROPERTY(Category = "ZeroG")
	FHazePlaySequenceData ZeroGExit;

	UPROPERTY(Category = "Settings")
	bool bLeftHandIK;
}

class ULocomotionFeatureSpaceTouchScreen : UHazeLocomotionFeatureBase
{
	default Tag = n"SpaceTouchScreen";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSpaceTouchScreenAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
