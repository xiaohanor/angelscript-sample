struct FLocomotionFeatureHoverboardSkydivingAnimData
{
	UPROPERTY(Category = "HoverboardSkydiving")
	FHazePlayBlendSpaceData Mh;

	UPROPERTY(Category = "HoverboardSkydiving")
	FHazePlayBlendSpaceData MhBanking;

	UPROPERTY(Category = "HoverboardSkydiving")
	FHazePlayRndSequenceData Trick;
}

class ULocomotionFeatureHoverboardSkydiving : UHazeLocomotionFeatureBase
{
	default Tag = n"HoverboardSkydiving";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureHoverboardSkydivingAnimData AnimData;
}
