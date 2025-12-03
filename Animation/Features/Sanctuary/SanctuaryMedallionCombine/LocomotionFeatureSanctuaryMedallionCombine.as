struct FLocomotionFeatureSanctuaryMedallionCombineAnimData
{
	UPROPERTY(Category = "SanctuaryMedallionCombine")
	FHazePlayBlendSpaceData BlendSpace;

	UPROPERTY(Category = "SanctuaryMedallionCombine")
	FHazePlaySequenceData Fail;
}

class ULocomotionFeatureSanctuaryMedallionCombine : UHazeLocomotionFeatureBase
{
	default Tag = n"SanctuaryMedallionCombine";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSanctuaryMedallionCombineAnimData AnimData;
}
