struct FLocomotionFeatureWalkingStickMovementAnimData
{
	UPROPERTY(Category = "WalkingStickMovement")
	FHazePlayBlendSpaceData Walk;

	UPROPERTY(Category = "WalkingStickMovement")
	FHazePlaySequenceData BriskWalk;

	UPROPERTY(Category = "WalkingStickMovement")
	FHazePlaySequenceData HitReactionFront;

	UPROPERTY(Category = "WalkingStickMovement")
	FHazePlaySequenceData HitReactionLeft;

	UPROPERTY(Category = "WalkingStickMovement")
	FHazePlaySequenceData HitReactionRight;

	UPROPERTY(Category = "WalkingStickMovement")
	FHazePlaySequenceData WalkTurnLeft;

	UPROPERTY(Category = "WalkingStickMovement")
	FHazePlaySequenceData WalkTurnRight;

	UPROPERTY(Category = "WalkingStickMovement")
	FHazePlayBlendSpaceData Turn;
}

class ULocomotionFeatureWalkingStickMovement : UHazeLocomotionFeatureBase
{
	default Tag = n"WalkingStickMovement";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureWalkingStickMovementAnimData AnimData;
}
