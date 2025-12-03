struct FTundra_SimonSaysStateUnspecifiedDelayData
{
	int DelayInBeats;
	FName DebugDelayName;
}

class UTundra_SimonSaysStateUnspecifiedDelayCapability : UTundra_SimonSaysStateBaseCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	FTundra_SimonSaysStateUnspecifiedDelayData CurrentData;

	int GetStateAmountOfBeats() const override
	{
		return CurrentData.DelayInBeats;
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
#if !RELEASE
		TemporalLog.Value("Delay Name", CurrentData.DebugDelayName);
#endif
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundra_SimonSaysStateUnspecifiedDelayData& Params) const
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
	void OnActivated(FTundra_SimonSaysStateUnspecifiedDelayData Params)
	{
		CurrentData = Params;
		Manager.ChangeMainState(ETundra_SimonSaysState::UnspecifiedDelay);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FTundra_SimonSaysStateDeactivatedParams Params)
	{
		Super::OnDeactivated(Params);
		StateComp.StateQueue.Finish(this);
	}
}