struct FLocomotionFeatureAnimateToAnimData
{
	UPROPERTY(Category = "AnimateTo")
	FHazePlaySequenceData DefaultAnimation;
}

class ULocomotionFeatureAnimateTo : UHazeLocomotionFeatureBase
{
	default Tag = n"AnimateTo";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureAnimateToAnimData AnimData;
}
