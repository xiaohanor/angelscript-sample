struct FLocomotionFeatureStepDashAnimData
{
	UPROPERTY(Category = "StepDash")
	FHazePlaySequenceData StepDashFwd;

	UPROPERTY(Category = "StepDash")
	FHazePlaySequenceData FwdToMh;

	UPROPERTY(Category = "StepDash")
	FHazePlaySequenceData FwdToRun;

	UPROPERTY(Category = "StepDash")
	FHazePlaySequenceData StepDashBwd;

	UPROPERTY(Category = "StepDash")
	FHazePlaySequenceData BwdToMh;

	UPROPERTY(Category = "StepDash")
	FHazePlaySequenceData BwdToRun;

	UPROPERTY(Category = "StepDash")
	FHazePlaySequenceData StepDashLeft;

	UPROPERTY(Category = "StepDash")
	FHazePlaySequenceData LeftToMh;

	UPROPERTY(Category = "StepDash")
	FHazePlaySequenceData LeftToRunLeft;

	UPROPERTY(Category = "StepDash")
	FHazePlaySequenceData StepDashRight;

	UPROPERTY(Category = "StepDash")
	FHazePlaySequenceData RightToMh;

	UPROPERTY(Category = "StepDash")
	FHazePlaySequenceData RightToRunRight;
}

class ULocomotionFeatureStepDash : UHazeLocomotionFeatureBase
{
	default Tag = n"StepDash";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureStepDashAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
