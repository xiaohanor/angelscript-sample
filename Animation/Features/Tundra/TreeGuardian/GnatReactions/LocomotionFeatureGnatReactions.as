namespace FeatureGnatReactions
{
	const FName GnatReactions = n"GnatReactions";
}

struct FLocomotionFeatureGnatReactionsAnimData
{
	UPROPERTY(Category = "GnatReactions")
	FHazePlaySequenceData Start;

	UPROPERTY(Category = "GnatReactions")
	FHazePlaySequenceData Mh;
	
	UPROPERTY(Category = "GnatReactions")
	FHazePlaySequenceData Exit;
}

class ULocomotionFeatureGnatReactions : UHazeLocomotionFeatureBase
{
	default Tag = FeatureGnatReactions::GnatReactions;

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureGnatReactionsAnimData AnimData;
}
