class UDentistBossToolDenturesHitShakeCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBossToolDentures Dentures;
	ADentistBoss Dentist;
	
	UDentistBossSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentures = Cast<ADentistBossToolDentures>(Owner);
		Dentist = TListedActors<ADentistBoss>().GetSingle();


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

		if(!Settings.bDenturesShakeStagger)
			return false;

		if(Time::GetGameTimeSince(Dentures.LastTimeGroundPounded) >= Settings.DenturesShakeDurationAfterHit)
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

		if(!Settings.bDenturesShakeStagger)
			return true;

		if(ActiveDuration >= Settings.DenturesShakeDurationAfterHit)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Dentures.bDamaged = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Dentures.bDamaged = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float StaggerAlpha = ActiveDuration / Settings.DenturesShakeDurationAfterHit;
		float CurveMultiplier = Settings.DenturesShakeCurve.GetFloatValue(StaggerAlpha);

		float ShakeAmountX = Math::Cos(ActiveDuration * Settings.DenturesShakeFrequency.X) * CurveMultiplier * Settings.DenturesShakeMagnitude.X;
		float ShakeAmountY = Math::Sin(ActiveDuration * Settings.DenturesShakeFrequency.Y) * CurveMultiplier * Settings.DenturesShakeMagnitude.Y;
		float ShakeAmountZ = Math::Sin(ActiveDuration * Settings.DenturesShakeFrequency.Z) * CurveMultiplier * Settings.DenturesShakeMagnitude.Z;
		FVector ShakeOffset = FVector(ShakeAmountX, ShakeAmountY, ShakeAmountZ);
		Dentures.MeshOffsetComp.RelativeLocation = ShakeOffset;
	}
};