
class UPlayerSequenceCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Sequencer");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AHazeLevelSequenceActor LastUsedLevelSequenceActor = nullptr;

	bool bHidingOutline = false;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		AHazeLevelSequenceActor SequenceActor = Player.GetActiveLevelSequenceActor();

		if (SequenceActor == nullptr)
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
    	AHazeLevelSequenceActor SequenceActor = Player.GetActiveLevelSequenceActor();

		if (SequenceActor == nullptr)
			return true;
			
		return false;
	}

    UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AHazeLevelSequenceActor SequenceActor = Player.GetActiveLevelSequenceActor();
		if (SequenceActor != nullptr)
		{
			LastUsedLevelSequenceActor = SequenceActor;

			if (SequenceActor.ShouldHideOutline(Player) == true)
				HideOutline();
		}
	}

    UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (LastUsedLevelSequenceActor != nullptr)
		{
			if (bHidingOutline)
				ClearOutline();
		}

		LastUsedLevelSequenceActor = nullptr;
	}

	private void HideOutline()
	{
		Player.BlockCapabilities(CapabilityTags::Outline, this);
		bHidingOutline = true;
	}

	private void ClearOutline()
	{
		Player.UnblockCapabilities(CapabilityTags::Outline, this);
		bHidingOutline = false;
	}
}