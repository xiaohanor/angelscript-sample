class ASanctuaryBossFinalPhaseZoeLight : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSphereComponent MioHazeSphere;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSphereComponent ZoeHazeSphere;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MioHazeSphere.SetRenderedForPlayer(Game::Zoe, false);
		ZoeHazeSphere.SetRenderedForPlayer(Game::Mio, false);
	}
};