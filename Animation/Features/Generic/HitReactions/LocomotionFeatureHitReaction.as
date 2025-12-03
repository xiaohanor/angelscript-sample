struct FLocomotionFeatureHitReactionAnimData
{
	UPROPERTY(Category = "HitReactionSmall")
	FHazePlaySequenceData HitReactionRightSmall;

	UPROPERTY(Category = "HitReactionBig")
	FHazePlaySequenceData HitReactionRightBig;
}

class ULocomotionFeatureHitReaction : UHazeLocomotionFeatureBase
{
	default Tag = n"HitReaction";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureHitReactionAnimData AnimData;
}
