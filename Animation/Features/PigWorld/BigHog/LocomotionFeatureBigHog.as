struct FLocomotionFeatureBigHogAnimData
{
	UPROPERTY(Category = "BigHog")
	FHazePlaySequenceData DefaultAnimation;
}

class ULocomotionFeatureBigHog : UHazeLocomotionFeatureBase
{
	default Tag = n"BigHog";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureBigHogAnimData AnimData;
}
