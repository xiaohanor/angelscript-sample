class AEvergreenPoleFlowerDisablerManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UBillboardComponent Visuals;
	default Visuals.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(EditAnywhere)
	TArray<AEvergreenPoleCrawler> Crawlers;

	UPROPERTY(EditAnywhere)
	TArray<ATutorialVolume> TutorialVolumes;

	int Count;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (AEvergreenPoleCrawler Crawler : Crawlers)
			Crawler.TheCrawlerWasKilled.AddUFunction(this, n"TheCrawlerWasKilled");
	
		for (ATutorialVolume Volume : TutorialVolumes)
			Volume.DisableForPlayer(Game::Zoe, this);
	}

	UFUNCTION()
	private void TheCrawlerWasKilled()
	{
		Count++;

		if (Count >= Crawlers.Num())
			DisableTutorials();
	}

	void DisableTutorials()
	{
		for (ATutorialVolume Volume : TutorialVolumes)
			Volume.AddActorDisable(this);
	}
};