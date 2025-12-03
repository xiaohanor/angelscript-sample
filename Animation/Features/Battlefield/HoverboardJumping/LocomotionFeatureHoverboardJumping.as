struct FLocomotionFeatureHoverboardJumpingAnimData
{
	UPROPERTY(Category = "HoverboardJumping")
	FHazePlaySequenceData Jump;

	UPROPERTY(Category = "HoverboardJumping")
	FHazePlaySequenceData JumpingBackwards;

	UPROPERTY(Category = "HoverboardJumping")
	FHazePlaySequenceData JumpingBackwardsTurnRight;

	UPROPERTY(Category = "HoverboardJumping")
	FHazePlayBlendSpaceData Banking;
}

class ULocomotionFeatureHoverboardJumping : UHazeLocomotionFeatureBase
{
	default Tag = n"HoverboardJumping";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureHoverboardJumpingAnimData AnimData;
}
