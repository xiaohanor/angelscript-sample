struct FLocomotionFeatureConstrainedByGeckoAnimData
{
	UPROPERTY(Category = "Constrained")
	FHazePlaySequenceData Constrained_Start;

	UPROPERTY(Category = "Constrained")
	FHazePlaySequenceData Constrained_MH;

	UPROPERTY(Category = "Constrained")
	FHazePlaySequenceData Constrained_Recover;
}

class ULocomotionFeatureConstrainedByGecko : UHazeLocomotionFeatureBase
{
	default Tag = n"ConstrainedByGecko";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureConstrainedByGeckoAnimData AnimData;
}
