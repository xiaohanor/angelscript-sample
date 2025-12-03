struct FTundra_SimonSaysStateWaitForPlayersToJumpToNextStageData
{

}

struct FTundra_SimonSaysStateWaitForPlayersToJumpToNextStageDeactivatedParams
{
	float StateDuration;
}

class UTundra_SimonSaysStateWaitForPlayersToJumpToNextStageCapability : UTundra_SimonSaysStateBaseCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	TPerPlayer<UTundra_SimonSaysPlayerComponent> SimonSaysComps;

	int LastBeat;
	bool bChangedBeat;
	bool bShouldEnd;
	int StartBeat;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		SimonSaysComps[0] = UTundra_SimonSaysPlayerComponent::GetOrCreate(Game::Mio);
		SimonSaysComps[1] = UTundra_SimonSaysPlayerComponent::GetOrCreate(Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!HasControl())
			return;

		int CurrentBeat = Manager.GetCurrentBeat();
		bChangedBeat = CurrentBeat > LastBeat;
		LastBeat = CurrentBeat;

		if(IsActive() && !bShouldEnd && IsBothPlayersOnNextStage())
		{
			bShouldEnd = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundra_SimonSaysStateWaitForPlayersToJumpToNextStageData& Params) const
	{
		if (StateComp.StateQueue.Start(this, Params))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride, Meta = (NoSuperCall))
	bool ShouldDeactivate(FTundra_SimonSaysStateWaitForPlayersToJumpToNextStageDeactivatedParams& Params) const
	{
		bool bResult = false;

		// We should end when both players have moved on to the next stage, but only when the beat changed this frame so we are synced.
		if(bChangedBeat && bShouldEnd)
			bResult = true;

		if(!StateComp.StateQueue.IsActive(this))
			bResult = true;

		if(bResult)
		{
			Params.StateDuration = (Manager.GetCurrentBeat() - StartBeat) * Manager.GetRealTimeBetweenBeats();
		}
		return bResult;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundra_SimonSaysStateWaitForPlayersToJumpToNextStageData Params)
	{
		bShouldEnd = false;
		StartBeat = Manager.GetCurrentBeat();
		Manager.ChangeMainState(ETundra_SimonSaysState::WaitForPlayersToJump);
	}

	UFUNCTION(BlueprintOverride, Meta = (NoSuperCall))
	void OnDeactivated(FTundra_SimonSaysStateWaitForPlayersToJumpToNextStageDeactivatedParams Params)
	{
		Manager.CompletedStatesTotalDuration += Params.StateDuration;
		StateComp.StateQueue.Finish(this);
	}

	bool IsBothPlayersOnNextStage() const
	{
		return IsPlayerOnNextStage(Game::Mio) && IsPlayerOnNextStage(Game::Zoe);
	}

	bool IsPlayerOnNextStage(AHazePlayerCharacter Player) const
	{
		return SimonSaysComps[Player].CurrentPerchedTile == Manager.GetTileForPlayer(Player, 0);
	}
}