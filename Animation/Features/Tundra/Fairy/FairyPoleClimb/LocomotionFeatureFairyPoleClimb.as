struct FLocomotionFeatureFairyPoleClimbAnimData
{
	UPROPERTY(Category = "FairyPoleClimb")
	FHazePlaySequenceData Slide;

	UPROPERTY(Category = "FairyPoleClimb")
	FHazePlaySequenceData Enter;
}


class ULocomotionFeatureFairyPoleClimb : UHazeLocomotionFeatureBase
{
	default Tag = n"PoleClimb";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureFairyPoleClimbAnimData AnimData;
}
