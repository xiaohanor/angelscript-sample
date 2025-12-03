class AWaterTempleInnerLevelActor : AHazeLevelScriptActor
{
	UFUNCTION()
	void ManuallySpawnBabyDragons()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			UPlayerBabyDragonComponent::Get(Player).SpawnBabyDragon(Player);
		}
	}
};