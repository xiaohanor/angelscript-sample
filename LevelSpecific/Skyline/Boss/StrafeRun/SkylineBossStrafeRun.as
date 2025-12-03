class ASkylineBossStrafeRun : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditDefaultsOnly)
	float Radius = 2000.0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (auto Player : Game::Players)
		{
			if (GetDistanceTo(Player) < Radius)
			{
			//	PrintToScreen("Player " + Player + " hit by StrafeRun", 2.0, FLinearColor::Green);
			}
		}
	}
}