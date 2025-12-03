struct FLocomotionFeatureStretchyPigJumpAnimData
{
	UPROPERTY(Category = "StretchyPigJump")
	FHazePlaySequenceData Jump;
}

class ULocomotionFeatureStretchyPigJump : UHazeLocomotionFeatureBase
{
	default Tag = n"Jump";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureStretchyPigJumpAnimData AnimData;
}
