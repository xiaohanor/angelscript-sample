/**
 * The first time any player enters this volume, force respawn the other player at the specified respawn point if they're dead.
 */
class AForceRespawnOtherPlayerTrigger : APlayerTrigger
{
	default Shape::SetVolumeBrushColor(this, FLinearColor(0.0, 1.0, 0.8, 1.0));

	UPROPERTY(EditAnywhere, Category = "Force Respawn")
	ARespawnPoint RespawnPoint;

	private bool bTriggered = false;

	void TriggerOnPlayerEnter(AHazePlayerCharacter Player) override
	{
		Super::TriggerOnPlayerEnter(Player);

		if (!bTriggered && IsValid(RespawnPoint))
		{
			bTriggered = true;

			if (Player.OtherPlayer.IsPlayerDead())
			{
				FRespawnLocation Location;
				Location.RespawnPoint = RespawnPoint;
				Location.RespawnRelativeTo = RespawnPoint.Root;

				auto RespawnComp = UPlayerRespawnComponent::Get(Player.OtherPlayer);
				RespawnComp.ApplyRespawnOverrideLocation(this, Location, EInstigatePriority::High);
				Timer::SetTimer(this, n"ClearRespawnOverrides", 0.1);
			}
		}
	}

	UFUNCTION()
	private void ClearRespawnOverrides()
	{
		for (auto Player : Game::Players)
		{
			auto RespawnComp = UPlayerRespawnComponent::Get(Player);
			RespawnComp.ClearRespawnOverride(this);
		}
	}
}