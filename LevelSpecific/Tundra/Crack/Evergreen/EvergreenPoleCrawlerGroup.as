class AEvergreenPoleCrawlerGroup : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditInstanceOnly)
	TArray<AEvergreenPoleCrawler> GroupedCrawlers;

	UPROPERTY(EditAnywhere)
	FSoundDefReference PoleCrawlerGroupSoundDef;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(GroupedCrawlers.Num() > 0 && PoleCrawlerGroupSoundDef.SoundDef.IsValid())
			PoleCrawlerGroupSoundDef.SpawnSoundDefAttached(this);
	}
}