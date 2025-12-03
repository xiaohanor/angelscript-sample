class ASanctuaryBossFinalPhaseMioGlowActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSphereComponent HazeSphereComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	ULensFlareComponent LensFlareComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeSphereComp.SetRenderedForPlayer(Game::Mio, false);
		LensFlareComp.SetRenderedForPlayer(Game::Mio, false);
	}

	UFUNCTION()
	void SmokeHit()
	{
		BP_SmokeHit();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_SmokeHit(){}
};