class UDentistBossToolDenturesWindupScrewRotateCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBossToolDentures Dentures;
	ADentistBoss Dentist;
	UDentistBossSettings Settings;

	FRotator ScrewRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentures = Cast<ADentistBossToolDentures>(Owner);
		Dentist = TListedActors<ADentistBoss>().Single;
		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Dentures.bActive)
			return false;

		if(Dentures.bDestroyed)
			return false;

		if(Dentures.bIsAttachedToJaw)
			return false;

		if(Dentures.HealthComp.IsDead())
			return false;

		if(!Dentures.bHasFinishedSpawning)
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Dentures.bActive)
			return true;

		if(Dentures.bDestroyed)
			return true;

		if(Dentures.bIsAttachedToJaw)
			return true;

		if(Dentures.HealthComp.IsDead())
			return true;

		if(!Dentures.bHasFinishedSpawning)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ScrewRotation = Dentures.WindupScrewMesh.RelativeRotation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float RotationSpeed = -Settings.DenturesWindDownRotationSpeed;
		if(Dentures.bIsRechargingJumps)
			RotationSpeed = Settings.DenturesWindupRotationSpeed;

		ScrewRotation -= FRotator(RotationSpeed * DeltaTime, 0.0, 0.0);
		Dentures.WindupScrewMesh.SetRelativeRotation(ScrewRotation);
	}
};