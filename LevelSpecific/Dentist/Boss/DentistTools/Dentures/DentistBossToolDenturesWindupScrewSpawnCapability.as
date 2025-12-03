class UDentistBossToolDenturesWindupScrewSpawnCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBossToolDentures Dentures;
	ADentistBoss Dentist;
	UDentistBossSettings Settings;

	FVector ScrewStartLocation;
	FRotator ScrewStartRotation;

	const FVector ScrewSpawnOffset = FVector(0.0, -90.0, 0.0);
	const float ScrewSpawnDuration = 0.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentures = Cast<ADentistBossToolDentures>(Owner);
		Dentist = TListedActors<ADentistBoss>().Single;
		Settings = UDentistBossSettings::GetSettings(Dentist);

		ScrewStartLocation = Dentures.WindupScrewMesh.RelativeLocation;
		ScrewStartRotation = Dentures.WindupScrewMesh.RelativeRotation;
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

		if(!Dentures.bHasLandedOnGround)
			return false;

		if(Dentures.bHasFinishedSpawning)
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

		if(ActiveDuration >= ScrewSpawnDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Dentures.WindupScrewMesh.RelativeLocation = ScrewStartLocation + ScrewSpawnOffset;
		Dentures.WindupScrewMesh.RelativeRotation = ScrewStartRotation;

		Dentures.WindupScrewMesh.RemoveComponentVisualsBlocker(Dentures);

		FDentistBossEffectHandlerOnDenturesWindupScrewSpawnStartParams EffectParams;
		EffectParams.ScrewRoot = Dentures.WindupScrewMesh;

		UDentistBossEffectHandler::Trigger_OnDenturesScrewStartSpawning(Dentist, EffectParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Dentures.WindupScrewMesh.RelativeLocation = ScrewStartLocation;
		Dentures.bHasFinishedSpawning = true;

		FDentistBossEffectHandlerOnDenturesWindupScrewSpawnStoppedParams EffectParams;
		EffectParams.ScrewRoot = Dentures.WindupScrewMesh;

		UDentistBossEffectHandler::Trigger_OnDenturesScrewStoppedSpawning(Dentist, EffectParams);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = ActiveDuration / ScrewSpawnDuration;

		Dentures.WindupScrewMesh.RelativeLocation = Math::Lerp(ScrewStartLocation + ScrewSpawnOffset, ScrewStartLocation, Alpha);
	}
};