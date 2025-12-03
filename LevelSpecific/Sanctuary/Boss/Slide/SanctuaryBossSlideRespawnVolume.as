class ASanctuaryBossSlideRespawnVolume : APlayerTrigger
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"HandlePlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"HandlePlayerLeave");

		for (auto Player : Game::Players)
		{
			if (IsPlayerInside(Player))
			{
				HandlePlayerEnter(Player);
			}
		}
	}

	UFUNCTION()
	private void HandlePlayerEnter(AHazePlayerCharacter Player)
	{
		FOnRespawnOverride RespawnOverride;
		RespawnOverride.BindUFunction(this, n"RespawnOnOtherPlayer");
		Player.ApplyRespawnPointOverrideDelegate(this, RespawnOverride);

		auto RespawnComp = UPlayerRespawnComponent::Get(Player);
		RespawnComp.OnPlayerRespawned.AddUFunction(this, n"HandlePlayerRespawned");

		UPlayerHealthSettings::SetGameOverWhenBothPlayersDead(Player, true, this);
	}

	UFUNCTION()
	private void HandlePlayerLeave(AHazePlayerCharacter Player)
	{
		Player.ClearRespawnPointOverride(this);

		auto RespawnComp = UPlayerRespawnComponent::Get(Player);
		RespawnComp.OnPlayerRespawned.Unbind(this, n"HandlePlayerRespawned");

		UPlayerHealthSettings::ClearGameOverWhenBothPlayersDead(Player, this);
	}

	UFUNCTION()
	private void HandlePlayerRespawned(AHazePlayerCharacter RespawnedPlayer)
	{
		RespawnedPlayer.ActorVelocity = RespawnedPlayer.OtherPlayer.ActorVelocity;
	}

	UFUNCTION()
	private bool RespawnOnOtherPlayer(AHazePlayerCharacter Player, FRespawnLocation& OutLocation)
	{
		OutLocation.RespawnRelativeTo = Player.OtherPlayer.RootComponent;
		
		
		//OutLocation.RespawnTransform.SetLocation(Player.OtherPlayer.ActorLocation);
		
		return true;
	}
};