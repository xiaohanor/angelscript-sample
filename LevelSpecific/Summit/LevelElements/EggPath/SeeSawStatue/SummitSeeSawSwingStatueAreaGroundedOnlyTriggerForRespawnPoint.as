class ASummitSeeSawSwingStatueAreaGroundedOnlyTriggerForRespawnPoint : AGroundedOnlyPlayerTrigger
{
	UPROPERTY(EditAnywhere, Category = "Setup")
	ARespawnPoint RespawnPoint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		for(auto LevelPlayer : Game::Players)
		{
			LevelPlayer.SetStickyRespawnPoint(RespawnPoint);
		}
		AddActorDisable(this);
	}
};