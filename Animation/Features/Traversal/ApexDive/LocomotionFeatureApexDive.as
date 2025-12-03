struct FLocomotionFeatureApexDiveAnimData
{
	UPROPERTY(Category = "ApexDive")
	FHazePlaySequenceData EnterAnimation_Var1;

	UPROPERTY(Category = "ApexDive")
	FHazePlaySequenceData DiveMH;
}

class ULocomotionFeatureApexDive : UHazeLocomotionFeatureBase
{
	default Tag = n"ApexDive";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureApexDiveAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
