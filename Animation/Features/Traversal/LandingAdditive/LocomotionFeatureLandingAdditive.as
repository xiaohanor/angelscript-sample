struct FLocomotionFeatureLandingAdditiveAnimData
{
	UPROPERTY(Category = "LandingAdditive")
	FHazePlaySequenceData DefaultAnimation;

	UPROPERTY(Category = "LandingAdditive")
	FHazePlayBlendSpaceData MediumLandingLeftFootBS;

	UPROPERTY(Category = "LandingAdditive")
	FHazePlayBlendSpaceData MediumLandingRightFootBS;
}

class ULocomotionFeatureLandingAdditive : UHazeLocomotionFeatureBase
{
	default Tag = n"LandingAdditive";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureLandingAdditiveAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
