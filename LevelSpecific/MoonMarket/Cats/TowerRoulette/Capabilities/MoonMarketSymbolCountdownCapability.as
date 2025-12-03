class UMoonMarketSymbolCountdownCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AMoonMarketSymbolRouletteManager Manager;

	float CountdownTime = 3.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = Cast<AMoonMarketSymbolRouletteManager>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Manager.State != EMoonMarketSymbolRouletteState::Countdown)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > CountdownTime)
			return true;

		if (Manager.State == EMoonMarketSymbolRouletteState::Disabled)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Manager.ShowAllCubeTimers();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Manager.HideAllCubeTimers();
		Manager.State = EMoonMarketSymbolRouletteState::CheckAnswer;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = ActiveDuration / CountdownTime;
		Manager.UpdateAllCubeTimers(Alpha);
	}
};