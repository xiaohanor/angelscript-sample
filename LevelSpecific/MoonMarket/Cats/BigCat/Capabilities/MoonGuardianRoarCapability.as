class UMoonGuardianRoarCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	AMoonGuardianCat GuardianCat;

	float Cooldown = 2.75;

	TArray<AHazePlayerCharacter> PlayersTargeted;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GuardianCat = Cast<AMoonGuardianCat>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(GuardianCat.bDevDisableScream)
			return false;

		if(GuardianCat.bIsSleeping)
			return false;
		
		if (GuardianCat.CurrentAwakeTime < GuardianCat.WakeUpTime)
			return false;

		if(GuardianCat.PlayersCurrentlyInside.IsEmpty())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= Cooldown)
			return true;

		if(GuardianCat.PlayersCurrentlyInside.IsEmpty())
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		GuardianCat.SleepState = EMoonGuardianSleepState::Awake;
		GuardianCat.AnimData.bRoaring = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GuardianCat.AnimData.bRoaring = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};