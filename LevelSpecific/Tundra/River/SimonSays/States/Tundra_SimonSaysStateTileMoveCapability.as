enum ETundra_SimonSaysStateSelectedMovingTiles
{
	All,
	NonIgnored,
	Ignored
}

struct FTundra_SimonSaysStateTileMoveData
{
	ETundra_SimonSaysStateSelectedMovingTiles TilesSelector = ETundra_SimonSaysStateSelectedMovingTiles::All;
	bool bMoveUp;
	int MoveDurationInBeats;
	int Stage;
	float MoveDistance;
	bool bSnap;
}

#if !RELEASE
struct FTundra_SimonSaysStateTileMoveFailedTileDebugData
{
	ACongaDanceFloorTile Tile;
	FInstigator MovingInstigator;
}
#endif

class UTundra_SimonSaysStateTileMoveCapability : UTundra_SimonSaysStateBaseCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	TArray<FTundra_SimonSaysTileData> Tiles;
	bool bMoveDone = false;
	FTundra_SimonSaysStateTileMoveData Data;
	bool bHasEnabledDisabledPerch = false;
#if !RELEASE
	TArray<FTundra_SimonSaysStateTileMoveFailedTileDebugData> DebugFailedTiles;
#endif

	TPerPlayer<UTundra_SimonSaysPlayerComponent> SimonSaysComps;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		for(AHazePlayerCharacter Player : Game::Players)
		{
			SimonSaysComps[Player] = UTundra_SimonSaysPlayerComponent::GetOrCreate(Player);
		}
	}

	int GetStateAmountOfBeats() const override
	{
		return Data.MoveDurationInBeats;
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
#if !RELEASE
		TemporalLog.Struct("Move Data", Data);

		float Alpha = Math::Saturate(ActiveDuration / (GetStateTotalTime()));
		if(!Data.bSnap)
			TemporalLog.Value("Move Alpha", Alpha);

		for(int i = 0; i < Tiles.Num(); i++)
		{
			TemporalLog.Value(f"10#Moving Tiles;Moving Tile {i}", Tiles[i].Tile.Name);
		}

		for(int i = 0; i < DebugFailedTiles.Num(); i++)
		{
			TemporalLog.Value(f"Failed Tile {i+1} Name", DebugFailedTiles[i].Tile.Name);
			TemporalLog.Value(f"Failed Tile {i+1} Moving Instigator", DebugFailedTiles[i].MovingInstigator.ToString());
		}
#endif
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundra_SimonSaysStateTileMoveData& Params) const
	{
		if (StateComp.StateQueue.Start(this, Params))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FTundra_SimonSaysStateDeactivatedParams& Params) const
	{
		if(bMoveDone)
		{
			Params.StateDuration = GetStateTotalTime();
			return true;
		}

		return Super::ShouldDeactivate(Params);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundra_SimonSaysStateTileMoveData Params)
	{
		if(!Data.bSnap && Data.TilesSelector == ETundra_SimonSaysStateSelectedMovingTiles::Ignored)
			Manager.OnCameraMoveToNextStage.Broadcast(Manager.GetCurrentDanceStageIndex());

		// Force out of floor wave capability because if it is active the move up will fail!
		Manager.BlockCapabilities(n"DanceFloorWave", this);
		Manager.UnblockCapabilities(n"DanceFloorWave", this);

		Data = Params;
		Manager.ChangeMainState(ETundra_SimonSaysState::MovePlatforms);
		Tiles.Reset();

		TArray<FTundra_SimonSaysTileData> MioTiles;
		TArray<FTundra_SimonSaysTileData> ZoeTiles;
		Manager.GetTilesForStage(Game::Mio, Data.Stage, MioTiles);
		Manager.GetTilesForStage(Game::Zoe, Data.Stage, ZoeTiles);

		RemoveRelevantTilesFromArray(MioTiles);
		RemoveRelevantTilesFromArray(ZoeTiles);

		Tiles = MioTiles;
		Tiles.Append(ZoeTiles);

		for(int i = Tiles.Num() - 1; i >= 0; i--)
		{
			ACongaDanceFloorTile Tile = Tiles[i].Tile;

			// If tile is already at end location, don't move.
			FVector End = GetEndForTile(Tile);
			if(Tile.ActorLocation.Equals(End))
			{
				Tiles.RemoveAt(i);
				continue;
			}

			if(!Manager.PrepareTileMove(Tile, this, Data.bMoveUp, 
				GetStateTotalTime() - ActiveDuration, GetMoveCurve(), GetStartForTile(Tile), GetEndForTile(Tile)))
			{
#if !RELEASE
				if(Manager.IsTileBeingMoved(Tile))
				{
					FTundra_SimonSaysStateTileMoveFailedTileDebugData DebugData;
					DebugData.Tile = Tile;
					DebugData.MovingInstigator = Manager.DebugGetTileMovingInstigator(Tile);
					DebugFailedTiles.Add(DebugData);
				}
#endif
				Tiles.RemoveAt(i);
				continue;
			}

			if(Data.bMoveUp)
			{
				Manager.AddUpTile(Tile);
			}
		}

		FTundra_SimonSaysManagerTilesMoveEffectParams EffectParams;
		EffectParams.bIsMiddleTiles = Data.TilesSelector == ETundra_SimonSaysStateSelectedMovingTiles::Ignored;

		if(!Data.bSnap)
		{
			if(Data.bMoveUp)
				UTundra_SimonSaysManagerEffectHandler::Trigger_OnTilesMoveUp(Manager, EffectParams);
			else
				UTundra_SimonSaysManagerEffectHandler::Trigger_OnTilesMoveDown(Manager, EffectParams);
		}

		for(int i = 0; i < Tiles.Num(); i++)
		{
			ACongaDanceFloorTile Tile = Tiles[i].Tile;

			FTundra_SimonSaysManagerTileMoveEffectParams EffectParams2;
			EffectParams2.Tile = Tile;
			
			for(AHazePlayerCharacter Player : Game::Players)
			{
				if(SimonSaysComps[Player].CurrentPerchedTile == Tile)
				{
					EffectParams2.Player = Player;
					break;
				}
			}
			
			EffectParams2.bIsMiddleTile = Manager.CanTileEverBeIgnored(Tile);
			EffectParams2.TileColor = Tile.CurrentColor;
			EffectParams2.TileTargetColor = Tile.InstigatedColor.Get();

			if(!Data.bSnap)
			{
				if(Data.bMoveUp)
					UTundra_SimonSaysManagerEffectHandler::Trigger_OnTileMoveUp(Manager, EffectParams2);
				else
					UTundra_SimonSaysManagerEffectHandler::Trigger_OnTileMoveDown(Manager, EffectParams2);
			}
		}

		bMoveDone = false;
		bHasEnabledDisabledPerch = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FTundra_SimonSaysStateDeactivatedParams Params)
	{
		// Only add to the total time of completed states if we didn't snap platforms, otherwise add nothing
		if(!Data.bSnap)
			Super::OnDeactivated(Params);

		StateComp.StateQueue.Finish(this);
		SetTileLocationsFromAlpha(1.0);

		for(int i = 0; i < Tiles.Num(); i++)
		{
			ACongaDanceFloorTile Tile = Tiles[i].Tile;
			Manager.EndTileMove(Tile, this);
			if(!Data.bMoveUp)
				Manager.RemoveUpTile(Tile);
		}

		if(!bHasEnabledDisabledPerch)
			EnableOrDisablePerchTargetables();

		if(!Data.bMoveUp && Data.TilesSelector == ETundra_SimonSaysStateSelectedMovingTiles::Ignored)
		{
			Manager.ClearColorsOfOldStage(Data.Stage);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = Math::Saturate(ActiveDuration / (GetStateTotalTime()));
		if(Data.bSnap)
			Alpha = 1.0;

		if(Alpha == 1.0)
			bMoveDone = true;

		SetTileLocationsFromAlpha(Alpha);
		HandleEnableOrDisablePerchTargetables(Alpha);
	}

	void SetTileLocationsFromAlpha(float Alpha)
	{
		for(int i = Tiles.Num() - 1; i >= 0; --i)
		{
			ACongaDanceFloorTile Tile = Tiles[i].Tile;
			
			FVector Start = GetStartForTile(Tile);
			FVector End = GetEndForTile(Tile);

			float MoveAlpha = GetMoveAlpha(Alpha);
			FVector NewLocation = Math::Lerp(Start, End, MoveAlpha);

			Tile.ActorLocation = NewLocation;
		}
	}

	FVector GetStartForTile(ACongaDanceFloorTile Tile)
	{
		if(Data.bMoveUp)
		{
			return Tile.GetOriginalLocation();
		}

		return Tile.GetOriginalLocation() + FVector::UpVector * Manager.TileMoveUpDistance;
	}

	FVector GetEndForTile(ACongaDanceFloorTile Tile)
	{
		if(Data.bMoveUp)
		{
			return Tile.GetOriginalLocation() + FVector::UpVector * Manager.TileMoveUpDistance;
		}

		return Tile.GetOriginalLocation();
	}

	float GetMoveAlpha(float InAlpha)
	{
		return GetMoveCurve().GetFloatValue(InAlpha);
	}

	FRuntimeFloatCurve& GetMoveCurve()
	{
		if(Data.bMoveUp)
			return Manager.TileMoveUpCurve;

		return Manager.TileMoveDownCurve;
	}

	void RemoveRelevantTilesFromArray(TArray<FTundra_SimonSaysTileData>& InTiles)
	{
		if(Data.TilesSelector == ETundra_SimonSaysStateSelectedMovingTiles::All)
			return;

		for(int i = InTiles.Num() - 1; i >= 0; i--)
		{
			bool bTileIsIgnored = Manager.IgnoredTiles.Contains(i);

			bool bSelectedNonIgnored = Data.TilesSelector == ETundra_SimonSaysStateSelectedMovingTiles::NonIgnored;

			if(bSelectedNonIgnored == bTileIsIgnored)
				InTiles.RemoveAt(i);
		}
	}

	void HandleEnableOrDisablePerchTargetables(float Alpha)
	{
		if(bHasEnabledDisabledPerch)
			return;

		float TargetAlpha = Data.bMoveUp ? Manager.CurveAlphaToEnablePerchOnMoveUp : Manager.CurveAlphaToDisablePerchOnMoveDown;

		if(Alpha < TargetAlpha)
			return;

		EnableOrDisablePerchTargetables();
		bHasEnabledDisabledPerch = true;
	}

	void EnableOrDisablePerchTargetables()
	{
		for(int i = 0; i < Tiles.Num(); i++)
		{
			ACongaDanceFloorTile Tile = Tiles[i].Tile;
			if(!Data.bMoveUp)
			{
				Tile.SimonSaysTargetable.Disable(Manager);
			}
			else
			{
				Tile.SimonSaysTargetable.Enable(Manager);
			}
		}
	}
}