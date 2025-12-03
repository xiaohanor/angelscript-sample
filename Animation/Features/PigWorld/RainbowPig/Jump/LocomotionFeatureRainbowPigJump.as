struct FLocomotionFeatureRainbowPigJumpAnimData
{
	UPROPERTY(Category = "RainbowPigJump")
	FHazePlaySequenceData Jump;
}

class ULocomotionFeatureRainbowPigJump : UHazeLocomotionFeatureBase
{
	default Tag = n"Jump";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureRainbowPigJumpAnimData AnimData;
}
