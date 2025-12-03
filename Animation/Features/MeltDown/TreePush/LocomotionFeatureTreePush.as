struct FLocomotionFeatureTreePushAnimData
{
	UPROPERTY(Category = "TreePush")
	FHazePlaySequenceData Push;

	UPROPERTY(Category = "TreePush")
	FHazePlaySequenceData Struggle;
}

class ULocomotionFeatureTreePush : UHazeLocomotionFeatureBase
{
	default Tag = n"TreePush";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureTreePushAnimData AnimData;
}
