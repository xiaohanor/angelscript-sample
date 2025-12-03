struct FLocomotionFeatureDarknessCrawlAnimData
{
	UPROPERTY(Category = "DarknessCrawl")
	FHazePlaySequenceData MH;

	UPROPERTY(Category = "DarknessCrawl")
	FHazePlaySequenceData Start;
	
	UPROPERTY(Category = "DarknessCrawl")
	FHazePlayBlendSpaceData MoveFwd;

	UPROPERTY(Category = "DarknessCrawl")
	FHazePlaySequenceData Stop;
}

class ULocomotionFeatureDarknessCrawl : UHazeLocomotionFeatureBase
{
	default Tag = n"DarknessCrawl";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureDarknessCrawlAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
