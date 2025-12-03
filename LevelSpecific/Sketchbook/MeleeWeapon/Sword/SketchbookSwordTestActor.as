class ASketchbookSwordTestActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;

	bool bIsEquipped = false;

	UFUNCTION(DevFunction)
	void EquipSword()
	{
		bIsEquipped = !bIsEquipped;
		for(auto Player : Game::GetPlayers())
		{
			if(bIsEquipped)
				RequestComp.StartInitialSheetsAndCapabilities(Player, this);
			else
				RequestComp.StopInitialSheetsAndCapabilities(Player, this);
		}
	}
};