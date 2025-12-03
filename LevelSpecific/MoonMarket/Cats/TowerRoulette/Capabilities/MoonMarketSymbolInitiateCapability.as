class UMoonMarketSymbolInitiateCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AMoonMarketSymbolRouletteManager Manager;
	float Duration = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = Cast<AMoonMarketSymbolRouletteManager>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Manager.State != EMoonMarketSymbolRouletteState::Initiate)
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
		Manager.ActivateHead();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (Manager.State != EMoonMarketSymbolRouletteState::Disabled)
		{
			Manager.ActivateRoulette();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};