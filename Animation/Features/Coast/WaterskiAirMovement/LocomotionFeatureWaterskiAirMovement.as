struct FLocomotionFeatureWaterskiAirMovementAnimData
{
	UPROPERTY(Category = "WaterskiAirMovement")
	FHazePlayBlendSpaceData Falling;

	UPROPERTY(Category = "WaterskiAirMovement")
	FHazePlayBlendSpaceData FallingHigh;
}

class ULocomotionFeatureWaterskiAirMovement : UHazeLocomotionFeatureBase
{
	default Tag = n"WaterskiAirMovement";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureWaterskiAirMovementAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
