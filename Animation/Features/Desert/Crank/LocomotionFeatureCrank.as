struct FLocomotionFeatureCrankAnimData
{
	UPROPERTY(Category = "CrankLeft")
	FHazePlaySequenceData LeftEnter;

	UPROPERTY(Category = "CrankLeft")
	FHazePlaySequenceData LeftMH;

	UPROPERTY(Category = "CrankLeft")
	FHazePlaySequenceData LeftTurn;

	UPROPERTY(Category = "CrankLeft")
	FHazePlaySequenceData LeftExit;


	UPROPERTY(Category = "CrankRight")
	FHazePlaySequenceData RightEnter;

	UPROPERTY(Category = "CrankRight")
	FHazePlaySequenceData RightMH;

	UPROPERTY(Category = "CrankRight")
	FHazePlaySequenceData RightTurn;

	UPROPERTY(Category = "CrankRight")
	FHazePlaySequenceData RightExit;

	
}

class ULocomotionFeatureCrank : UHazeLocomotionFeatureBase
{
	default Tag = n"Crank";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureCrankAnimData AnimData;
}
