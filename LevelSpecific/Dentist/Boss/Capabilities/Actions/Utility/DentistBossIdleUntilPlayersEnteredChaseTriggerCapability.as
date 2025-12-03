class UDentistBossIdleUntilPlayersEnteredChaseTriggerCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBoss Dentist;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Dentist.bFinalChaseStarted)
			return true;

		return false;
	}
};