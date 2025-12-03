class AEvergreenPoleCrawlerSpawnManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UBillboardComponent Visuals;
	default Visuals.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(EditAnywhere)
	AEvergreenPoleCrawler Crawler;

	UPROPERTY(EditAnywhere)
	TArray<APoleClimbRespawnPoint> RespawnPoints;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Crawler.TheCrawlerWasKilled.AddUFunction(this, n"TheCrawlerWasKilled");
	
		for (APoleClimbRespawnPoint Respawn : RespawnPoints)
			Respawn.DisableForPlayer(Game::Mio, this);
	}

	UFUNCTION()
	private void TheCrawlerWasKilled()
	{
		for (APoleClimbRespawnPoint Respawn : RespawnPoints)
			Respawn.EnableForPlayer(Game::Mio, this);
	}
};