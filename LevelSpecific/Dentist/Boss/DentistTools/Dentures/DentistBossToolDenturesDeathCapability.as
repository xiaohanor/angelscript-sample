class UDentistBossToolDenturesDeathCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBossToolDentures Dentures;
	ADentistBoss Dentist;

	UDentistBossSettings Settings;

	bool bHasEnabledInteract = false;

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
		if(Dentures.bDestroyed)
			return false;

		if(!Dentures.bActive)
			return false;

		if(Dentures.bIsAttachedToJaw)
			return false;

		if(!Dentures.bHasLandedOnGround)
			return false;

		if(!Dentures.HealthComp.IsDead())
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

		if(!Dentures.HealthComp.IsDead())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Dentures.ToothResponseComp.OnDashImpact = EDentistToothDashImpactResponse::Disabled;

		Dentures.WindupScrewMesh.AddComponentVisualsBlocker(Dentures);

		FDentistBossEffectHandlerOnDenturesKilledByGroundPoundParams KilledParams;
		KilledParams.WindupScrewLocation = Dentures.WindupScrewMesh.WorldLocation;
		KilledParams.WindupScrewRotation = Dentures.WindupScrewMesh.WorldRotation;
		UDentistBossEffectHandler::Trigger_OnDenturesKilledByGroundPound(Dentist, KilledParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Dentures.InteractComp.Disable(Dentures);
		bHasEnabledInteract = false;
		Dentures.ToothResponseComp.OnDashImpact = EDentistToothDashImpactResponse::Backflip;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bHasEnabledInteract)
			return;
		
		const float InteractEnableDelay = Network::PingRoundtripSeconds + Settings.DenturesRechargeRotateBackDuration + 0.2;
		if(ActiveDuration > InteractEnableDelay)
			EnableInteractComponent();
	}

	private void EnableInteractComponent()
	{
		bHasEnabledInteract = true;
		Dentures.InteractComp.Enable(Dentures);
	}
};