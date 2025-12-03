class UMimicChestCatCaughtCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AMoonMarketMimic Mimic;
	float TotalOpenTimeForSequence = 4.0;
	bool bCatInternalCollected;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Mimic = Cast<AMoonMarketMimic>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Mimic.bEatingACat)
			return false;

		if (!Mimic.bCatCollected)
			return false;

		if (bCatInternalCollected)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > TotalOpenTimeForSequence)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		//Mimic.InteractComp.Enable(Mimic);
		bCatInternalCollected = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};