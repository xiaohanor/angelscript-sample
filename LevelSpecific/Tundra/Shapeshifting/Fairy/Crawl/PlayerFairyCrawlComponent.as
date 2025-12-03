struct FTundraPlayerFairyCrawlAnimData
{
	bool bIsExitingCrawl = false;
}

class UTundraPlayerFairyCrawlComponent : UActorComponent
{
	ATundraPlayerFairyCrawlSplineActor CurrentCrawlSplineActor;
	ATundraPlayerFairyCrawlSplineActor PreviousCrawlSplineActor;
	AHazeCameraActor CurrentActiveCameraActor;
	bool bReversed = false;
	bool bIsInCrawl = false;
	FSplinePosition CurrentSplinePosition;
	FTundraPlayerFairyCrawlAnimData AnimData;
}