struct FTundra_SimonSaysStatePlayerToMonkeyPlayerStatusData
{
	int BeatDuration;
}

class UTundra_SimonSaysStatePlayerToMonkeyPlayerStatusCapability : UTundra_SimonSaysStateBaseCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	int BeatDuration;

	int GetStateAmountOfBeats() const override
	{
		return BeatDuration;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundra_SimonSaysStatePlayerToMonkeyPlayerStatusData& Params) const
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
	void OnActivated(FTundra_SimonSaysStatePlayerToMonkeyPlayerStatusData Params)
	{
		BeatDuration = Params.BeatDuration;
		Manager.ChangeMainState(ETundra_SimonSaysState::PlayerToMonkeyPlayerStatus);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FTundra_SimonSaysStateDeactivatedParams Params)
	{
		Super::OnDeactivated(Params);
		StateComp.StateQueue.Finish(this);
		Manager.OnClearStatusOnTiles();
	}
}