struct FLocomotionFeatureHopscotchAnimData
{
	UPROPERTY(Category = "Hopscotch")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "Hopscotch")
	FHazePlayBlendSpaceData Jump;

	UPROPERTY(Category = "Hopscotch")
	FHazePlaySequenceData Land;
}

class ULocomotionFeatureHopscotch : UHazeLocomotionFeatureBase
{
	default Tag = n"Perch";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureHopscotchAnimData AnimData;
}
