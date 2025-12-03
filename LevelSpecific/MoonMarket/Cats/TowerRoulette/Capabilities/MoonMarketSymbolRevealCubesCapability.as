class UMoonMarketSymbolRevealCubesCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AMoonMarketSymbolRouletteManager Manager;

	float TotalTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = Cast<AMoonMarketSymbolRouletteManager>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Manager.State != EMoonMarketSymbolRouletteState::SetLine)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > TotalTime)
			return true;

		if (Manager.State == EMoonMarketSymbolRouletteState::Disabled)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Manager.SetLine();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Manager.State = EMoonMarketSymbolRouletteState::RouletteSpin;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PrintToScreen("Reveal Cubes");
	}
};