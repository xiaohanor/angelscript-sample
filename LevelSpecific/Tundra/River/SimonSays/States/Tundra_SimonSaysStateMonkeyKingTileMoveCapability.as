struct FTundra_SimonSaysStateMonkeyKingTileMoveData
{
	bool bMoveUp;
	int MoveDurationInBeats;
	float MoveDistance;
	bool bSnap;
	bool bShouldDeactivateSimonSays;
}

class UTundra_SimonSaysStateMonkeyKingTileMoveCapability : UTundra_SimonSaysStateBaseCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	TArray<ATundra_SimonSaysMonkeyKingTile> Tiles;
	bool bMoveDone = false;
	FTundra_SimonSaysStateMonkeyKingTileMoveData Data;

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
			TemporalLog.Value(f"10#Moving Tiles;Moving Tile {i}", Tiles[i].Name);
		}
#endif
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundra_SimonSaysStateMonkeyKingTileMoveData& Params) const
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
	void OnActivated(FTundra_SimonSaysStateMonkeyKingTileMoveData Params)
	{
		Data = Params;
		Manager.ChangeMainState(ETundra_SimonSaysState::MoveMonkeyKingPlatforms);
		Manager.GetTilesForMonkeyKing(Tiles);

		for(int i = Tiles.Num() - 1; i >= 0; i--)
		{
			ATundra_SimonSaysMonkeyKingTile Tile = Tiles[i];

			// If tile is already at end location, don't move.
			FVector End = GetEndForTile(Tile);
			if(Tile.ActorLocation.Equals(End))
			{
				Tiles.RemoveAt(i);
				continue;
			}

			FTundra_SimonSaysManagerMonkeyKingTileMoveEffectParams EffectParams2;
			EffectParams2.Tile = Tile;

			if(!Data.bMoveUp && !Data.bSnap)
				UTundra_SimonSaysManagerEffectHandler::Trigger_OnMonkeyKingTileMoveDown(Manager, EffectParams2);
		}

		bMoveDone = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FTundra_SimonSaysStateDeactivatedParams Params)
	{
		// Only add to the total time of completed states if we didn't snap platforms, otherwise add nothing
		if(!Data.bSnap)
			Super::OnDeactivated(Params);

		StateComp.StateQueue.Finish(this);
		SetTileLocationsFromAlpha(1.0);

		if(Data.bShouldDeactivateSimonSays)
		{
			Manager.Deactivate();
			Manager.bDeactivatePending = false;
			Manager.OnWinSimonSays.Broadcast();

			for(AHazePlayerCharacter Player : Game::Players)
			{
				Player.DeactivateCamera(Manager.MonkeyCamera);
				Player.UnblockCapabilities(CapabilityTags::GameplayAction, Manager);
			}

			if(Manager.bDebug)
				PrintScaled("You won!!!");
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
	}

	void SetTileLocationsFromAlpha(float Alpha)
	{
		for(int i = Tiles.Num() - 1; i >= 0; --i)
		{
			ATundra_SimonSaysMonkeyKingTile Tile = Tiles[i];
			
			FVector Start = GetStartForTile(Tile);
			FVector End = GetEndForTile(Tile);

			float MoveAlpha = GetMoveAlpha(Alpha);
			FVector NewLocation = Math::Lerp(Start, End, MoveAlpha);

			Tile.ActorLocation = NewLocation;
		}
	}

	FVector GetStartForTile(ATundra_SimonSaysMonkeyKingTile Tile)
	{
		if(Data.bMoveUp)
		{
			return Tile.GetOriginalLocation();
		}

		return Tile.GetOriginalLocation() + FVector::UpVector * Data.MoveDistance;
	}

	FVector GetEndForTile(ATundra_SimonSaysMonkeyKingTile Tile)
	{
		if(Data.bMoveUp)
		{
			return Tile.GetOriginalLocation() + FVector::UpVector * Data.MoveDistance;
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
}