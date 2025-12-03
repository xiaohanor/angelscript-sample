struct FLocomotionFeatureAIEnforcerJetpackLeapAnimData
{
	UPROPERTY(Category = "EnforcerJetpack")
	FHazePlaySequenceData Leap;
}

class ULocomotionFeatureAIEnforcerJetpackLeap : UHazeLocomotionFeatureBase
{
	default Tag = LocomotionFeatureAISkylineTags::JetpackLeapForward;

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureAIEnforcerJetpackLeapAnimData AnimData;
}
