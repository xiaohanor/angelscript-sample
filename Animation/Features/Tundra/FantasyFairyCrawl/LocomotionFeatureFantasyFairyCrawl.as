struct FLocomotionFeatureFantasyFairyCrawlAnimData
{
	UPROPERTY(Category = "FantasyFairyCrawl")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "FantasyFairyCrawl")
	FHazePlaySequenceData MhToCrawl;

	UPROPERTY(Category = "FantasyFairyCrawl")
	FHazePlaySequenceData CrawlStart;

	UPROPERTY(Category = "FantasyFairyCrawl")
	FHazePlaySequenceData CrawlLoop;

	UPROPERTY(Category = "FantasyFairyCrawl")
	FHazePlaySequenceData CrawlStop;

	UPROPERTY(Category = "FantasyFairyCrawl")
	FHazePlaySequenceData CrawlMh;

	UPROPERTY(Category = "FantasyFairyCrawl")
	FHazePlaySequenceData CrawlToMh;
}

class ULocomotionFeatureFantasyFairyCrawl : UHazeLocomotionFeatureBase
{
	default Tag = n"FantasyFairyCrawl";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureFantasyFairyCrawlAnimData AnimData;
}
