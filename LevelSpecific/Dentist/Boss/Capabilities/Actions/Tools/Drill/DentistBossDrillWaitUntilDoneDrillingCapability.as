class UDentistBossDrillWaitUntilDoneDrillingCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBoss Dentist;
	UDentistBossTargetComponent TargetComp;

	bool bHasStartedDrillingOnce = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
		TargetComp = UDentistBossTargetComponent::Get(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!bHasStartedDrillingOnce)
			return false;

		if(TargetComp.bIsDrilling)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bHasStartedDrillingOnce = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(TargetComp.bIsDrilling)
			bHasStartedDrillingOnce = true;
	}	
};