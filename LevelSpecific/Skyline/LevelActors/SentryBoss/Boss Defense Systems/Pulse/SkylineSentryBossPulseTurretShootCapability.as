class USkylineSentryBossPulseTurretShootCapability : UHazeCapability
{
	default CapabilityTags.Add(n"PulseTurretShoot");


	ASkylineSentryBossPulseTurret PulseTurret;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PulseTurret = Cast<ASkylineSentryBossPulseTurret>(Owner);	
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!PulseTurret.bHasRisen)
			return false;

		if (DeactiveDuration < PulseTurret.FireInterval)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PulseTurret.Shoot();
	}
}