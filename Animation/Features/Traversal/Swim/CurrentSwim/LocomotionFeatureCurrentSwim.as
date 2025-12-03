struct FLocomotionFeatureCurrentSwimAnimData
{
	UPROPERTY(Category = "CurrentSwim")
	FHazePlayBlendSpaceData SwimBlendSpace;
}

class ULocomotionFeatureCurrentSwim : UHazeLocomotionFeatureBase
{
	default Tag = n"CurrentSwim";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureCurrentSwimAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
