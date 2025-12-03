struct FLocomotionFeaturePaddleRaftHitReactionAnimData
{
	UPROPERTY(Category = "PaddleRaftHitReaction")
	FHazePlaySequenceData HitreactionFrontLeftMh;

	UPROPERTY(Category = "PaddleRaftHitReaction")
	FHazePlaySequenceData HitreactionFrontRightMh;

	UPROPERTY(Category = "PaddleRaftHitReaction")
	FHazePlaySequenceData HitreactionBackLeftMh;
	
	UPROPERTY(Category = "PaddleRaftHitReaction")
	FHazePlaySequenceData HitreactionBackRightMh;

	UPROPERTY(Category = "PaddleRaftHitReaction")
	FHazePlaySequenceData HitreactionLeftLeftMh;

	UPROPERTY(Category = "PaddleRaftHitReaction")
	FHazePlaySequenceData HitreactionLeftRightMh;

	UPROPERTY(Category = "PaddleRaftHitReaction")
	FHazePlaySequenceData HitreactionRightLeftMh;

	UPROPERTY(Category = "PaddleRaftHitReaction")
	FHazePlaySequenceData HitreactionRightRightMh;
}

class ULocomotionFeaturePaddleRaftHitReaction : UHazeLocomotionFeatureBase
{
	default Tag = n"PaddleRaftHitReaction";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeaturePaddleRaftHitReactionAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
