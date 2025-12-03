class UMoonMarketSymbolCheckAnswerCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AMoonMarketSymbolRouletteManager Manager;
	bool bAnsweredCorrectly;
	
	float Duration = 1.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = Cast<AMoonMarketSymbolRouletteManager>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Manager.State != EMoonMarketSymbolRouletteState::CheckAnswer)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > Duration)
			return true;

		if (Manager.State == EMoonMarketSymbolRouletteState::Disabled)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bAnsweredCorrectly = Manager.HasCorrectAnswer();
		Manager.SetCubeAnswerColours();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (bAnsweredCorrectly)
		{
			if (Manager.HasCompleted())
			{
				Manager.CompleteRoulette();
				return;
			}
			
			Manager.IncrementLineIndex();
			Manager.State = EMoonMarketSymbolRouletteState::SetLine;
		}
		else
		{
			Manager.ResetPlayers();
			Manager.DeactivateRoulette();
			Manager.State = EMoonMarketSymbolRouletteState::Disabled;
		}
	}
};