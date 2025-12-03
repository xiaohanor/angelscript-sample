class UMoonGuardianAwakeCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AMoonGuardianCat GuardianCat;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GuardianCat = Cast<AMoonGuardianCat>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(GuardianCat.bIsSleeping)
			return false;

		// if (GuardianCat.bCatCaught)
		// 	return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(GuardianCat.bIsSleeping)
			return true;

		// if (GuardianCat.bCatCaught)
		// 	return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		GuardianCat.OnAwake.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		GuardianCat.CurrentAwakeTime += DeltaTime;
	}
};