struct FLocomotionFeatureWaterskiLandingAnimData
{
	UPROPERTY(Category = "WaterskiLanding")
	FHazePlayBlendSpaceData Landing;
}

class ULocomotionFeatureWaterskiLanding : UHazeLocomotionFeatureBase
{
	default Tag = n"WaterskiLanding";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureWaterskiLandingAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
