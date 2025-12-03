struct FLocomotionFeatureDecimatorPortalAnimData
{
	UPROPERTY(Category = "DecimatorPortal")
	FHazePlaySequenceData Enter;

	UPROPERTY(Category = "DecimatorPortal")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "DecimatorPortal")
	FHazePlaySequenceData Exit;

	UPROPERTY(Category = "DecimatorPortal")
	FHazePlaySequenceData WaitingMh;
}

class ULocomotionFeatureDecimatorPortal : UHazeLocomotionFeatureBase
{
	default Tag = n"DecimatorPortal";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureDecimatorPortalAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
