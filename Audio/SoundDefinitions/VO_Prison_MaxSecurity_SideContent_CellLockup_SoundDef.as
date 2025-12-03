
struct FSideContentCellLookPlayerData
{
	UPROPERTY()
	bool bInside = false;

	UPROPERTY()
	bool bSitting = false;
}

UCLASS(Abstract)
class UVO_Prison_MaxSecurity_SideContent_CellLockup_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditInstanceOnly)
	AThreeShotInteractionActor SitdownMio;
	
	UPROPERTY(EditInstanceOnly)
	AThreeShotInteractionActor SitdownZoe;

	UPROPERTY(EditInstanceOnly)
	APlayerTrigger CellTrigger;

	UPROPERTY(EditInstanceOnly)
	AOneShotInteractionActor LockingInteraction;

	UPROPERTY()
	bool bCellLocked = true;

	UPROPERTY()
	bool bBothInCell = false;

	UPROPERTY()
	int BothInCellIndex = 0;

	UPROPERTY()
	TPerPlayer<FSideContentCellLookPlayerData> PlayersInCell;

	UFUNCTION(BlueprintPure)
	bool BothInsideCell() const
	{
		for (const auto& Data: PlayersInCell)
		{
			if (!Data.bInside)
				return false;
		} 

		return true;
	}

	UFUNCTION(BlueprintPure)
	bool BothInsideCellAndSittingDown() const
	{
		for (const auto& Data: PlayersInCell)
		{
			if (!Data.bInside || !Data.bSitting)
				return false;
		} 

		return true;
	}

	UFUNCTION(BlueprintPure)
	AHazePlayerCharacter GetPlayerInside()
	{
		for (auto Player : Game::Players)
		{
			if (PlayersInCell[Player].bInside)
				return Player;
		}

		return nullptr;
	}

	UFUNCTION(BlueprintPure)
	bool IsPlayerInside(AHazePlayerCharacter Player)
	{
		return PlayersInCell[Player].bInside;
	}

	UFUNCTION()
	void SetPlayerInside(AHazePlayerCharacter Player, bool bInside)
	{
		PlayersInCell[Player].bInside = bInside;
	}

	UFUNCTION()
	void SetPlayerSitting(AHazePlayerCharacter Player, bool bSitting)
	{
		PlayersInCell[Player].bSitting = bSitting;
	}

	UFUNCTION(BlueprintPure)
	bool CanPlayLockedLine(AHazePlayerCharacter Player)
	{
		if (!bCellLocked)
			return false;

		if (!IsPlayerInside(Player))
			return false;

		if (BothInsideCell())
			return false;

		return true;
	}
}