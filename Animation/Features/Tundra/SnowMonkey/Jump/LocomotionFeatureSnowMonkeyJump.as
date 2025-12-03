struct FLocomotionFeatureSnowMonkeyJumpAnimData
{
	UPROPERTY(Category = "SnowMonkeyJump")
	FHazePlaySequenceData JumpStart;

	UPROPERTY(Category = "SnowMonkeyJump")
	FHazePlaySequenceData JumpStartFwd;

	UPROPERTY(Category = "SnowMonkeyJump")
	FHazePlaySequenceData JumpStartFwdFromLandFwd;
}

class ULocomotionFeatureSnowMonkeyJump : UHazeLocomotionFeatureBase
{
	default Tag = n"Jump";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSnowMonkeyJumpAnimData AnimData;
}
