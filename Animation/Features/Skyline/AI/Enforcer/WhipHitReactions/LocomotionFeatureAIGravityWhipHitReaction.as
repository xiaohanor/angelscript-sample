struct FLocomotionFeatureAIGravityWhipHitReactionAnimData
{
	UPROPERTY(Category = "HitReaction")
	FHazePlaySequenceData HitReaction;

	UPROPERTY(Category = "HitReaction")
	FHazePlayBlendSpaceData GravityWhipHitReaction;

	UPROPERTY(Category = "HitReaction")
	FHazePlayBlendSpaceData GravityWhipMoveDirection;

	UPROPERTY(Category = "HitReaction")
	FHazePlayBlendSpaceData GravityWhipHitReactionRecovery;
}

class ULocomotionFeatureAIGravityWhipHitReaction : UHazeLocomotionFeatureBase
{
	default Tag = LocomotionFeatureAISkylineTags::GravityWhipHitReaction;

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureAIGravityWhipHitReactionAnimData AnimData;
}
