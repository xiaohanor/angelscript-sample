struct FLocomotionFeatureWindWalkAnimData
{
	UPROPERTY(Category = "WindWalk")
	FHazePlayBlendSpaceData LocomotionBS;
}

class ULocomotionFeatureWindWalk : UHazeLocomotionFeatureBase
{
	default Tag = n"WindWalk";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureWindWalkAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
