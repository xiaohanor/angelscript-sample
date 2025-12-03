class UDentistBossIdleUntilDenturesAreDestroyedCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBoss Dentist;
	ADentistBossToolDentures Dentures;

	FVector StartLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
		Dentures = Cast<ADentistBossToolDentures>(Dentist.Tools[EDentistBossTool::Dentures]);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Dentures.bDestroyed)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Dentist.bShouldHaveMaskOverride = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Dentist.bShouldHaveMaskOverride = false;
	}
};