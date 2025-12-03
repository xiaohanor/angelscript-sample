class ASanctuaryBossInsideDisableHazardVolume : APlayerTrigger
{
	UPROPERTY(EditInstanceOnly)
	TArray<AHazeActor> DisabledHazards;

	int PlayersInVolume = 0;

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
		PlayersInVolume++;

		for (auto Hazard : DisabledHazards)
		{
			//Disable Rain
			auto Rain = Cast<ASanctuaryBossInsideRainManager>(Hazard);
			if (IsValid(Rain))
			{
				Rain.Deactivate(Player);
			}

			//Disable Waves
			if (PlayersInVolume > 0)
			{
				auto Wave = Cast<ASanctuaryBossInsideWave>(Hazard);
				if (IsValid(Wave))
				{
					Wave.Deactivate();
				}
			}
		}
	}

	UFUNCTION()
	private void HandlePlayerLeave(AHazePlayerCharacter Player)
	{
		PlayersInVolume--;

		for (auto Hazard : DisabledHazards)
		{
			//Enable Rain
			auto Rain = Cast<ASanctuaryBossInsideRainManager>(Hazard);
			if (IsValid(Rain))
			{
				Rain.Activate(Player);
			}

			//Disable Waves
			if (PlayersInVolume == 0)
			{
				auto Wave = Cast<ASanctuaryBossInsideWave>(Hazard);
				if (IsValid(Wave))
				{
					Wave.Activate();
				}
			}
		}
	}
};