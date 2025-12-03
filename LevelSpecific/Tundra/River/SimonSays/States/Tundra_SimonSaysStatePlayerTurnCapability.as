struct FTundra_SimonSaysStatePlayerTurnData
{
	float PlayerSequenceBeatMultiplier;
}

class UTundra_SimonSaysStatePlayerTurnCapability : UTundra_SimonSaysStateBaseCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroupOrder = 125;

	TArray<FTundra_SimonSaysTileData> ValidTiles;

	UTundra_SimonSaysPlayerComponent MioSimonSaysComp;
	UTundra_SimonSaysPlayerComponent ZoeSimonSaysComp;

	int LastBeat;
	bool bChangedBeat;
	bool bShouldEnd;
	int StartBeat;
	float PlayerSequenceBeatMultiplier;
	float TimeOfShouldEnd = -100.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		MioSimonSaysComp = UTundra_SimonSaysPlayerComponent::GetOrCreate(Game::Mio);
		ZoeSimonSaysComp = UTundra_SimonSaysPlayerComponent::GetOrCreate(Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!HasControl())
			return;

		int CurrentBeat = Manager.GetCurrentBeat();
		bChangedBeat = CurrentBeat > LastBeat;
		LastBeat = CurrentBeat;

		if(IsActive() && !bShouldEnd)
		{
			if(MioSimonSaysComp.HasSucceeded() && ZoeSimonSaysComp.HasSucceeded())
				bShouldEnd = true;

			if(MioSimonSaysComp.HasFailed() || ZoeSimonSaysComp.HasFailed())
				bShouldEnd = true;

			if(bShouldEnd)
				TimeOfShouldEnd = Time::GetGameTimeSeconds();
		}
	}

	int GetStateAmountOfBeats() const override
	{
		float Duration = Manager.GetCurrentDanceSequenceLength() * PlayerSequenceBeatMultiplier;
		int Beats = Math::CeilToInt(Duration);
		return Beats;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundra_SimonSaysStatePlayerTurnData& Params) const
	{
		if (StateComp.StateQueue.Start(this, Params))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride, Meta = (NoSuperCall))
	bool ShouldDeactivate(FTundraSimonSaysStatePlayerTurnDeactivatedParams& Params) const
	{
		bool bResult = false;

		// If someone fails or both succeed we should end player turn but only on a beat and only until at least one full beat has passed since fail/succeed
		if(bChangedBeat && bShouldEnd && Time::GetGameTimeSince(TimeOfShouldEnd) > Manager.GetRealTimeBetweenBeats())
			bResult = true;

		if(!StateComp.StateQueue.IsActive(this))
			bResult = true;

		if(Manager.GetCurrentStateActiveDuration() >= GetStateTotalTime())
			bResult = true;

		if(bResult)
		{
			Params.StateDuration = (Manager.GetCurrentBeat() - StartBeat) * Manager.GetRealTimeBetweenBeats();
			Params.bMioSucceeded = MioSimonSaysComp.HasSucceeded();
			Params.bZoeSucceeded = ZoeSimonSaysComp.HasSucceeded();
			bool bMioFail = MioSimonSaysComp.HasFailed();
			bool bZoeFail = ZoeSimonSaysComp.HasFailed();
			if(!bMioFail && !bZoeFail)
			{
				bMioFail = !Params.bMioSucceeded;
				bZoeFail = !Params.bZoeSucceeded;
			}
			
			if(bMioFail == bZoeFail)
				Params.FailPlayerReason = bMioFail ? EHazeSelectPlayer::Both : EHazeSelectPlayer::None;
			else
				Params.FailPlayerReason = bMioFail ? EHazeSelectPlayer::Mio : EHazeSelectPlayer::Zoe;
		}

		return bResult;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundra_SimonSaysStatePlayerTurnData Params)
	{
		bShouldEnd = false;
		PlayerSequenceBeatMultiplier = Params.PlayerSequenceBeatMultiplier;
		StartBeat = Manager.GetCurrentBeat();
		Manager.ChangeMainState(ETundra_SimonSaysState::PlayerTurn);
		Manager.OnPlayerMeasureStart.Broadcast();

		Manager.GetTilesForPlayer(Game::Mio, ValidTiles);
		for(int i = ValidTiles.Num() - 1; i >= 0; --i)
		{
			if(Manager.IgnoredTiles.Contains(i))
				ValidTiles.RemoveAt(i);
		}

		TArray<FTundra_SimonSaysTileData> ZoeTiles;
		Manager.GetTilesForPlayer(Game::Zoe, ZoeTiles);
		for(int i = ZoeTiles.Num() - 1; i >= 0; --i)
		{
			if(Manager.IgnoredTiles.Contains(i))
				ZoeTiles.RemoveAt(i);
		}

		ValidTiles.Append(ZoeTiles);
	}

	UFUNCTION(BlueprintOverride, Meta = (NoSuperCall))
	void OnDeactivated(FTundraSimonSaysStatePlayerTurnDeactivatedParams Params)
	{
		// We don't want to call super here since player turns might be shorter than expected if player succeeds/fails early, add the total time manually instead!
		Manager.CompletedStatesTotalDuration += Params.StateDuration;

		StateComp.StateQueue.Finish(this);

		for(FTundra_SimonSaysTileData TileData : ValidTiles)
		{
			TileData.Tile.Disable(this);
		}

		ValidTiles.Empty();

		Manager.OnPlayerMeasureEnd.Broadcast();

		Manager.OnPlayerEndedMeasure.Broadcast(Game::Mio, Params.bMioSucceeded);
		Manager.OnPlayerEndedMeasure.Broadcast(Game::Zoe, Params.bZoeSucceeded);

		Manager.UpdateTileStatusForPlayer(Game::Mio, true);
		Manager.UpdateTileStatusForPlayer(Game::Zoe, true);

		if(Params.bMioSucceeded && Params.bZoeSucceeded)
		{
			Manager.OnBothPlayersSuccessful.Broadcast();
			UTundra_SimonSaysManagerEffectHandler::Trigger_OnSuccessfulStage(Manager);
		}
		else
		{
			Manager.OnEitherPlayerFailed.Broadcast();
			FTundra_SimonSaysManagerFailStageEffectParams EffectParams;
			EffectParams.FailedPlayers = Params.FailPlayerReason;
			UTundra_SimonSaysManagerEffectHandler::Trigger_OnFailStage(Manager, EffectParams);
		}

		for(auto AnimComp : Manager.AnimComps)
		{
			if(Params.bMioSucceeded && Params.bZoeSucceeded)
				AnimComp.Value.AnimData.bIsSuccess = true;
			else
				AnimComp.Value.AnimData.bIsFail = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for(int i = 0; i < ValidTiles.Num(); i++)
		{
			FTundra_SimonSaysTileData TileData = ValidTiles[i];

			if(TileData.Tile.IsAnyPlayerOnTile())
				TileData.Tile.Enable(this);
			else
				TileData.Tile.Disable(this);
		}
	}
}

struct FTundraSimonSaysStatePlayerTurnDeactivatedParams
{
	float StateDuration;
	bool bMioSucceeded;
	bool bZoeSucceeded;
	EHazeSelectPlayer FailPlayerReason;
}