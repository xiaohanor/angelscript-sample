struct FLocomotionFeatureAIGravityBladeHitReactionAnimData
{
	UPROPERTY(Category = "HitReaction")
	FHazePlaySequenceData HitReaction;

	UPROPERTY(Category = "HitReaction")
	FHazePlayBlendSpaceData GravityBladeHitReaction;

	UPROPERTY(Category = "HitReaction")
	FHazePlayBlendSpaceData GravityBladeMoveDirection;

	UPROPERTY(Category = "HitReaction")
	FHazePlayBlendSpaceData GravityBladeHitReactionRecovery;
}

class ULocomotionFeatureAIGravityBladeHitReaction : UHazeLocomotionFeatureBase
{
	default Tag = LocomotionFeatureAISkylineTags::GravityBladeHitReaction;

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureAIGravityBladeHitReactionAnimData AnimData;
}
