class UMimicChestCatWaitingCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AMoonMarketMimic Mimic;

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
		
		if (Mimic.bCatCollected)
			return false;

		if (Mimic.bWasKicked)
			return false;

		if(!Mimic.bEatingCatStarted)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Mimic.bCatCollected)
			return true;


		// if (Mimic.bWasKicked)
		// 	return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Mimic.BP_PlayReadyTimeline();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Mimic.BP_StopReadyTimeline();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		
	}
};