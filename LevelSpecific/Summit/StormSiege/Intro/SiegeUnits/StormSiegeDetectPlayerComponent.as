class UStormSiegeDetectPlayerComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	float AggressionRange = 30000.0;

	private TArray<AHazePlayerCharacter> AvailablePlayers;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if ((Player.ActorLocation - Owner.ActorLocation).Size() <= AggressionRange)
				AvailablePlayers.AddUnique(Player);
			else if (AvailablePlayers.Contains(Player)) 
				AvailablePlayers.Remove(Player);
		}	
	}

	TArray<AHazePlayerCharacter> GetAvailablePlayers()
	{
		return AvailablePlayers;
	}

	bool HasAvailablePlayers()
	{
		return GetAvailablePlayers().Num() > 0;
	}
}