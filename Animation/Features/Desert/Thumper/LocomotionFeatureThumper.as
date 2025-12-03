struct FLocomotionFeatureThumperAnimData
{
	UPROPERTY(Category = "ThumperLeft")
	FHazePlaySequenceData LeftEnter;

	UPROPERTY(Category = "ThumperLeft")
	FHazePlaySequenceData LeftMH;

	UPROPERTY(Category = "ThumperLeft")
	FHazePlaySequenceData LeftTurn;

	UPROPERTY(Category = "ThumperLeft")
	FHazePlaySequenceData LeftExit;


	UPROPERTY(Category = "ThumperRight")
	FHazePlaySequenceData RightEnter;

	UPROPERTY(Category = "ThumperRight")
	FHazePlaySequenceData RightMH;

	UPROPERTY(Category = "ThumperRight")
	FHazePlaySequenceData RightTurn;

	UPROPERTY(Category = "ThumperRight")
	FHazePlaySequenceData RightExit;
}

class ULocomotionFeatureThumper : UHazeLocomotionFeatureBase
{
	default Tag = n"Thumper";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureThumperAnimData AnimData;
}
