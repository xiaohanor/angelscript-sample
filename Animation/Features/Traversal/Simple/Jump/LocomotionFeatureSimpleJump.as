struct FLocomotionFeatureSimpleJumpAnimData
{
	UPROPERTY(Category = "Jump")
	FHazePlaySequenceData Jump;
}

class ULocomotionFeatureSimpleJump : UHazeLocomotionFeatureBase
{
	default Tag = n"Jump";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSimpleJumpAnimData AnimData;
}
