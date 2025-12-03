class AStormRideDragonSpike : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	float KillRadius = 250.0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (GetDistanceTo(Player) < KillRadius)
				PrintToScreen("KILL PLAYER: " + Player.Name);
		}
	}

	UFUNCTION(CrumbFunction)
	void Crumb_KillPlayer()
	{

	}
}