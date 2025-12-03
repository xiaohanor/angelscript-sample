class ASolarFlarePlayerKillBothOnDeathVolume : APlayerTrigger
{
	UPROPERTY(EditAnywhere)
	TSubclassOf<UDeathEffect> DeathEffect;

	TArray<AHazePlayerCharacter> Player;
	TPerPlayer<bool> bPlayerIsInside;

	TPerPlayer<UPlayerHealthComponent> HealthComps;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"PlayerEntered");
		OnPlayerLeave.AddUFunction(this, n"PlayerLeft");

		for (AHazePlayerCharacter CurrentPlayer : Game::Players)
		{
			HealthComps[CurrentPlayer] = UPlayerHealthComponent::Get(CurrentPlayer);
			HealthComps[CurrentPlayer].OnDeathTriggered.AddUFunction(this, n"OnDeathTriggered");
		}
	}

	UFUNCTION()
	private void OnDeathTriggered()
	{
		for (AHazePlayerCharacter CurrentPlayer : Game::Players)
		{
			if (!CurrentPlayer.IsPlayerDead() && bPlayerIsInside[CurrentPlayer])
			{
				CurrentPlayer.KillPlayer(FPlayerDeathDamageParams(-FVector::ForwardVector, 25.0), DeathEffect);
			}
		}
	}

	UFUNCTION()
	private void PlayerEntered(AHazePlayerCharacter CurrentPlayer)
	{
		bPlayerIsInside[CurrentPlayer] = true;
	}

	UFUNCTION()
	private void PlayerLeft(AHazePlayerCharacter CurrentPlayer)
	{
		bPlayerIsInside[CurrentPlayer] = false;
	}
};