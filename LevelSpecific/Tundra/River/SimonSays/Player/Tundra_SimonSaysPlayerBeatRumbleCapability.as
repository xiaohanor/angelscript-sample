struct FTundra_SimonSaysPlayerBeatRumbleActivatedParams
{
	bool bBigRumble;
}

class UTundra_SimonSaysPlayerBeatRumbleCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::AfterGameplay;
	
	UTundra_SimonSaysPlayerComponent PlayerComp;
	ATundra_SimonSaysManager Manager;
	int LastBeatRumbleTriggeredAt = -1;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UTundra_SimonSaysPlayerComponent::GetOrCreate(Player);
		Manager = PlayerComp.Manager;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundra_SimonSaysPlayerBeatRumbleActivatedParams& Params) const
	{
		if(!HasControl())
			return false;

		if(Manager.GetTimeToNextBeat() > -Manager.BeatRumbleTimeOffset)
			return false;

		if(Manager.GetCurrentBeat() == LastBeatRumbleTriggeredAt)
			return false;
		
		Params.bBigRumble = Manager.GetCurrentStateActiveDuration() < Manager.GetRealTimeBetweenBeats() && 
			(Manager.GetMainState() == ETundra_SimonSaysState::MonkeyTurn || Manager.GetMainState() == ETundra_SimonSaysState::PlayerTurn);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundra_SimonSaysPlayerBeatRumbleActivatedParams Params)
	{
		LastBeatRumbleTriggeredAt = Manager.GetCurrentBeat();

		if(Params.bBigRumble)
			Player.PlayForceFeedback(Manager.BigRumble, false, false, this);
		else
			Player.PlayForceFeedback(Manager.BeatRumble, false, false, this);
	}
}