struct FLocomotionFeatureStrafeJumpAnimData
{
	UPROPERTY(Category = "StrafeJump")
	FHazePlayBlendSpaceData StrafeJumpBS;

	UPROPERTY(Category = "StrafeJump")
	FHazePlayBlendSpaceData StrafeDoubleJumpBS;
}

class ULocomotionFeatureStrafeJump : UHazeLocomotionFeatureBase
{
	default Tag = n"StrafeJump";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureStrafeJumpAnimData AnimData;
}
