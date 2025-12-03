struct FLocomotionFeatureEnforcerMinimalHitReactionAnimData
{
	UPROPERTY(Category = "EnforcerMinimalHitReaction")
	FHazePlaySequenceData EnforcerMinimalHitReaction;
}

class ULocomotionFeatureEnforcerMinimalHitReaction : UHazeLocomotionFeatureBase
{
	default Tag = n"EnforcerMinimalHitReaction";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureEnforcerMinimalHitReactionAnimData AnimData;
}
