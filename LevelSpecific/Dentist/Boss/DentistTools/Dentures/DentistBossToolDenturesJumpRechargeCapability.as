class UDentistBossToolDenturesJumpRechargeCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBossToolDentures Dentures;
	ADentistBoss Dentist;

	UDentistBossSettings Settings;

	bool bHasStartedRotatingBack = false;

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

		if(Dentures.HealthComp.IsDead())
			return false;

		if(Dentures.JumpsSinceRecharge < Settings.DenturesJumpsBeforeRecharge)
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

		if(ActiveDuration >= Settings.DenturesJumpRechargeDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Dentures.bIsRechargingJumps = true;
		bHasStartedRotatingBack = false;
		Dentures.bFallingOverJump = false;

		Dentures.ToggleWeakpointLight(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Dentures.bIsRechargingJumps = false;
		Dentures.bIsRotatingBack = false;
		Dentures.JumpsSinceRecharge = 0;

		if(!bHasStartedRotatingBack)
			StartRotatingBack();

		Dentures.ToggleWeakpointLight(false);

		Dentures.EyesSpringinessEnabled.Clear(Dentures);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bHasStartedRotatingBack
		&& ActiveDuration >= Settings.DenturesJumpRechargeDuration - Settings.DenturesRechargeRotateBackDuration)
			StartRotatingBack();
	}

	void StartRotatingBack()
	{
		Dentures.KnockAwayPlayersStandingOnDentures();
		bHasStartedRotatingBack = true;
		Dentures.bIsRotatingBack = true;

		FDentistBossEffectHandlerOnDenturesFlipParams EventParams;
		EventParams.Dentures = Dentures;
		UDentistBossEffectHandler::Trigger_OnDenturesFlipBack(Dentist, EventParams);

		FVector UpImpulse = FVector::UpVector * 2000.0;
		Dentures.AddMovementImpulse(UpImpulse);
	}
};