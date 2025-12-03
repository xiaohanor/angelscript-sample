class AMoonMarketBlockRespawnVolume : APlayerTrigger
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"OnBlock");
		OnPlayerLeave.AddUFunction(this, n"OnUnblock");
	}

	UFUNCTION()
	private void OnUnblock(AHazePlayerCharacter Player)
	{
		Player.BlockCapabilities(n"Respawn", this);
	}

	UFUNCTION()
	private void OnBlock(AHazePlayerCharacter Player)
	{
		Player.UnblockCapabilities(n"Respawn", this);
	}
};