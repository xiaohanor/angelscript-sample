class ASkylineHighwayActionModeVolume : APlayerTrigger
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		OnPlayerEnter.AddUFunction(this, n"HandlePlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"HandlePlayerLeave");
	}

	UFUNCTION()
	private void HandlePlayerEnter(AHazePlayerCharacter Player)
	{
		Player.ApplyActionMode(EPlayerActionMode::ForceActionMode, EInstigatePriority::Level, this);
	}

	UFUNCTION()
	private void HandlePlayerLeave(AHazePlayerCharacter Player)
	{
		Player.ClearActionMode(this);
	}
};