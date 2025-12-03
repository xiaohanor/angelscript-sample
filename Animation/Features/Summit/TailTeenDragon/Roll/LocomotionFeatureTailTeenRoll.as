struct FLocomotionFeatureTailTeenRollAnimData
{
	UPROPERTY(Category = "TailTeenRoll")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "TailTeenRoll")
	FHazePlayBlendSpaceData Roll;

	UPROPERTY(Category = "TailTeenRoll")
	FHazePlaySequenceData RollJumpEnter;

	UPROPERTY(Category = "TailTeenRoll")
	FHazePlaySequenceData RollJumpMh;

	UPROPERTY(Category = "TailTeenRoll")
	FHazePlaySequenceData RollJumpExit;

	UPROPERTY(Category = "TailTeenRoll")
	FHazePlaySequenceData RollJumpEnterHit;

	UPROPERTY(Category = "TailTeenRoll")
	FHazePlaySequenceData ExitToMH;

	UPROPERTY(Category = "TailTeenRoll")
	FHazePlaySequenceData ExitToMovement;
}

class ULocomotionFeatureTailTeenRoll : UHazeLocomotionFeatureBase
{
	default Tag = n"RollMovement";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureTailTeenRollAnimData AnimData;
}
