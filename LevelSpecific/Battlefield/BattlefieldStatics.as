namespace Battlefield
{
	UFUNCTION(BlueprintCallable)
	void SavePlayerTrickPoints(AHazePlayerCharacter Player)
	{
		UBattlefieldHoverboardTrickComponent::Get(Player).SaveTrickPoints();
	}

	UFUNCTION(BlueprintCallable)
	void LoadPlayerTrickPoints(bool bNaturalProgression)
	{
		if(bNaturalProgression)
			return;
		
		for(auto Player : Game::Players)
			UBattlefieldHoverboardTrickComponent::Get(Player).LoadTrickPoints();
	}
}