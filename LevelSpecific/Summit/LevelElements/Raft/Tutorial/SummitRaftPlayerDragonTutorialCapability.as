struct FSummitRaftPlayerHoldTutorialDeactivateParams
{
	bool bWasCompleted = false;
}

class USummitRaftPlayerDragonTutorialCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::Input);
	default TickGroup = EHazeTickGroup::Input;

	USummitRaftPlayerDragonTutorialComponent TutorialComp;

	float RealTimeWhenStarted = MAX_flt;
	float RealTimeWhenStartedActioning = MAX_flt;
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TutorialComp = USummitRaftPlayerDragonTutorialComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!TutorialComp.bHasActivePrompt)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSummitRaftPlayerHoldTutorialDeactivateParams& Params) const
	{
		if (!TutorialComp.bHasActivePrompt)
			return true;

		float HeldDuration = Time::GetRealTimeSince(RealTimeWhenStartedActioning);
		if (HeldDuration >= TutorialComp.Data.HoldDuration)
		{
			Params.bWasCompleted = true;
			return true;
		}

		float RealtimeActiveDuration = Time::GetRealTimeSince(RealTimeWhenStarted);
		if (TutorialComp.Data.MaxDuration >= 0 && RealtimeActiveDuration >= TutorialComp.Data.MaxDuration)
		{
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		RealTimeWhenStarted = Time::RealTimeSeconds;
		RealTimeWhenStartedActioning = MAX_flt;

		if (IsActioning(TutorialComp.Data.Prompt.Action))
			RealTimeWhenStartedActioning = Time::RealTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSummitRaftPlayerHoldTutorialDeactivateParams Params)
	{
		if (Params.bWasCompleted)
			TutorialComp.Data.OnCompleted.ExecuteIfBound();
		else
			TutorialComp.Data.OnTimedout.ExecuteIfBound();

		TutorialComp.RemoveTutorial();
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
		TemporalLog.Value("RealTimeActive", Time::GetRealTimeSince(RealTimeWhenStarted));
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (WasActionStarted(TutorialComp.Data.Prompt.Action))
			RealTimeWhenStartedActioning = Time::GetRealTimeSeconds();

		if (WasActionStopped(TutorialComp.Data.Prompt.Action))
			RealTimeWhenStartedActioning = MAX_flt;
	}
};