
class USkipSequenceShowUICapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(n"Sequencer");
	
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	AHazeLevelSequenceActor LastUsedLevelSequenceActor = nullptr;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		AHazeLevelSequenceActor SequenceActor = Player.GetActiveLevelSequenceActor();

		if (SequenceActor == nullptr)
			return false;

		if (SequenceActor.SkippableSetting == EHazeSkippableSetting::None)
			return false;
			
		if (!IsActioning(ActionNames::SkipCutscene))
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
    	AHazeLevelSequenceActor SequenceActor = Player.GetActiveLevelSequenceActor();

		if (SequenceActor == nullptr)
			return true;

		if (SequenceActor.SkippableSetting == EHazeSkippableSetting::None)
			return true;
			
		if (!WasActionStoppedDuringTime(ActionNames::SkipCutscene, 0.5) && !IsActioning(ActionNames::SkipCutscene))
			return true;
			
		return false;
	}

    UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AHazeLevelSequenceActor SequenceActor = Player.GetActiveLevelSequenceActor();
		if (SequenceActor != nullptr)
		{
			SequenceActor.SetPlayerWantsToShowSkipUI(Player.Player, true);
			LastUsedLevelSequenceActor = SequenceActor;
		}
	}

    UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (LastUsedLevelSequenceActor != nullptr)
		{
			LastUsedLevelSequenceActor.SetPlayerWantsToShowSkipUI(Player.Player, false);
			LastUsedLevelSequenceActor = nullptr;
		}
	}
}