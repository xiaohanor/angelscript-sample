class UDentistBossToolDenturesHealthBarCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBossToolDentures Dentures;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentures = Cast<ADentistBossToolDentures>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Dentures.bDestroyed)
			return false;

		if(!Dentures.bActive)
			return false;

		if(Dentures.bIsAttachedToJaw)
			return false;

		if(!Dentures.bHasLandedOnGround)
			return false;

		if(Dentures.HealthComp.IsDead())
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Dentures.bDestroyed)
			return true;

		if(!Dentures.bActive)
			return true;

		if(Dentures.bIsAttachedToJaw)
			return true;

		if(!Dentures.bHasLandedOnGround)
			return true;

		if(Dentures.HealthComp.IsDead())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Dentures.HealthBarComp.SetHealthBarEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Dentures.HealthBarComp.SetHealthBarEnabled(false);
	}
};