struct FLocomotionFeatureTailAdultDragonAnimData
{
	UPROPERTY(Category = "TailAdultDragon")
	FHazePlayBlendSpaceData DefaultBlendSpace;
}

class ULocomotionFeatureTailAdultDragon : UHazeLocomotionFeatureBase
{
	default Tag = n"TailAdultDragon";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureTailAdultDragonAnimData AnimData;
}
