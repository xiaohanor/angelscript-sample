class AMoonMarketCancelShapeshiftVolume : APlayerTrigger
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		Player.BlockCapabilities(n"MoonMarketShapeShift", this);
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		Player.UnblockCapabilities(n"MoonMarketShapeShift", this);
	}
};