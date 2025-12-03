struct FLocomotionFeatureSnowMonkeyGrindJumpAnimData
{
	UPROPERTY(Category = "GrindJump")
	FHazePlaySequenceData Jump;
}

class ULocomotionFeatureSnowMonkeyGrindJump : UHazeLocomotionFeatureBase
{
	default Tag = n"Jump";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSnowMonkeyGrindJumpAnimData AnimData;
}
