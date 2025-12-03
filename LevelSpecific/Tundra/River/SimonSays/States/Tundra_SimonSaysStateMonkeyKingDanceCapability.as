struct FTundra_SimonSaysStateMonkeyKingDanceData
{
	int BeatDuration;
	int TileIndex;
	bool bIsLast;
}

class UTundra_SimonSaysStateMonkeyKingDanceCapability : UTundra_SimonSaysStateBaseCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	FTundra_SimonSaysSequence CurrentSequence;
	TArray<ATundra_SimonSaysMonkeyKingTile> Tiles;

	int BeatDuration;
	bool bIsLast;
	int TargetTileIndex;
	float StartStateActiveDuration;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Manager.GetTilesForMonkeyKing(Tiles);
	}

	int GetStateAmountOfBeats() const override
	{
		return BeatDuration;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundra_SimonSaysStateMonkeyKingDanceData& Params) const
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
	void OnActivated(FTundra_SimonSaysStateMonkeyKingDanceData Params)
	{
		BeatDuration = Params.BeatDuration;
		bIsLast = Params.bIsLast;
		TargetTileIndex = Params.TileIndex;

		if(Manager.GetMainState() != ETundra_SimonSaysState::MonkeyTurn)
		{
			Manager.ChangeMainState(ETundra_SimonSaysState::MonkeyTurn);
			Manager.OnMonkeyMeasureStart.Broadcast();
		}

		Manager.MonkeyKingMoveData.bShouldBeActive = true;
		Manager.MonkeyKingMoveData.TargetTileIndex = TargetTileIndex;

		StartStateActiveDuration = Manager.GetCurrentStateActiveDuration();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FTundra_SimonSaysStateDeactivatedParams Params)
	{
		Super::OnDeactivated(Params);
		StateComp.StateQueue.Finish(this);

		Manager.MonkeyKingMoveData.bShouldBeActive = false;
		
		// Check whether manager has begun play so we don't call the event if we're streaming out (restart from checkpoint)
		if(bIsLast && Manager.HasActorBegunPlay())
		{
			Manager.OnMonkeyMeasureEnd.Broadcast();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Move alpha is only used on the control side.
		if(!HasControl())
			return;

		float Alpha = (Manager.GetCurrentStateActiveDuration() - StartStateActiveDuration) / (GetStateTotalTime() - StartStateActiveDuration);
		Manager.MonkeyKingMoveData.MoveAlpha = Alpha;
	}
}