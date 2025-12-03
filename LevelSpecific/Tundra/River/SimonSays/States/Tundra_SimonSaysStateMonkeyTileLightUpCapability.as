struct FTundra_SimonSaysStateMonkeyTileLightUpData
{
	int BeatDuration;
	int TileIndex;
	bool bIsLast;
}

class UTundra_SimonSaysStateMonkeyTileLightUpCapability : UTundra_SimonSaysStateBaseCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	TArray<ACongaDanceFloorTile> ActiveTiles;
	bool bIsLast;
	int BeatDuration;

	int GetStateAmountOfBeats() const override
	{
		return BeatDuration;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundra_SimonSaysStateMonkeyTileLightUpData& Params) const
	{
		if (StateComp.StateQueue.Start(this, Params))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FTundra_SimonSaysStateDeactivatedParams& Params) const
	{
		return Super::ShouldDeactivate(Params);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundra_SimonSaysStateMonkeyTileLightUpData Params)
	{
		BeatDuration = Params.BeatDuration;
		bIsLast = Params.bIsLast;

		if(Manager.GetMainState() != ETundra_SimonSaysState::MonkeyTurn)
		{
			Manager.ChangeMainState(ETundra_SimonSaysState::MonkeyTurn);
			Manager.OnMonkeyMeasureStart.Broadcast();
		}

		FTundra_SimonSaysTileStage MioStage;
		FTundra_SimonSaysTileStage ZoeStage;

		Manager.GetCurrentTileStageForPlayer(Game::Mio, MioStage);
		Manager.GetCurrentTileStageForPlayer(Game::Zoe,ZoeStage);

		ActiveTiles.Add(MioStage.Tiles[Params.TileIndex].Tile);
		ActiveTiles.Add(ZoeStage.Tiles[Params.TileIndex].Tile);

		for(int i = 0; i < ActiveTiles.Num(); i++)
		{
			ActiveTiles[i].Enable(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FTundra_SimonSaysStateDeactivatedParams Params)
	{
		Super::OnDeactivated(Params);
		StateComp.StateQueue.Finish(this);

		if(bIsLast)
			Manager.OnMonkeyMeasureEnd.Broadcast();

		for(int i = 0; i < ActiveTiles.Num(); i++)
		{
			ActiveTiles[i].Disable(this);
		}

		ActiveTiles.Empty();
	}
}