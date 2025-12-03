struct FLocomotionFeatureAIJetpackTraverseAnimData
{
	UPROPERTY(Category = "EnforcerJetpack")
	FHazePlaySequenceData Launch;

	UPROPERTY(Category = "EnforcerJetpack")
	FHazePlayBlendSpaceData FlyingBS;

	UPROPERTY(Category = "EnforcerJetpack")
	FHazePlayBlendSpaceData FlyUpBS;

	UPROPERTY(Category = "EnforcerJetpack")
	FHazePlaySequenceData Land;
}

class ULocomotionFeatureAIJetpackTraverse : UHazeLocomotionFeatureBase
{
	default Tag = LocomotionFeatureAISkylineTags::JetpackTraverse;

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureAIJetpackTraverseAnimData AnimData;
}
