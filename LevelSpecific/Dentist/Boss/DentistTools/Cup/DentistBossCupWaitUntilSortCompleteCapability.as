class UDentistBossCupWaitUntilSortCompleteCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UDentistBossCupSortingComponent SortingComp;
	ADentistBoss Dentist;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
		SortingComp = UDentistBossCupSortingComponent::GetOrCreate(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (SortingComp.NetworkSortingComplete[Game::Mio] && SortingComp.NetworkSortingComplete[Game::Zoe])
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ADentistBossCupManager CupManager = Dentist.CupManager;
		CupManager.bCupSortingFinished = true;
	}
};