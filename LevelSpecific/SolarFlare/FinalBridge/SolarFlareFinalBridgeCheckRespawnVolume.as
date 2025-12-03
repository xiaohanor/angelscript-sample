event void FOnSolarFlareOnBothPlayersEntered();
event void FOnSolarFlareNoPlayersInside();

class ASolarFlareFinalBridgeCheckRespawnVolume : APlayerTrigger
{
	UPROPERTY()
	FOnSolarFlareOnBothPlayersEntered OnSolarFlareOnBothPlayersEntered;
	UPROPERTY()
	FOnSolarFlareNoPlayersInside OnSolarFlareNoPlayersInside;
	TArray<AHazePlayerCharacter> PlayersInside;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"OnNewPlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"OnNewPlayerLeave");
	}

	UFUNCTION()
	private void OnNewPlayerEnter(AHazePlayerCharacter Player)
	{
		PlayersInside.AddUnique(Player);
		if (PlayersInside.Num() == 2)
			OnSolarFlareOnBothPlayersEntered.Broadcast();
	}

	UFUNCTION()
	private void OnNewPlayerLeave(AHazePlayerCharacter Player)
	{
		PlayersInside.Remove(Player);
		if (PlayersInside.Num() == 0)
			OnSolarFlareNoPlayersInside.Broadcast();
	}
};