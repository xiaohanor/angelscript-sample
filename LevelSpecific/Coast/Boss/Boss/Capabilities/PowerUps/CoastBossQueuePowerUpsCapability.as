class UCoastBossQueuePowerUpsCapability : UHazeCapability
{
	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default TickGroup = EHazeTickGroup::Gameplay;
	
	ACoastBossActorReferences References;
	ACoastBoss CoastBoss;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CoastBoss = Cast<ACoastBoss>(Owner);
		CoastBossDevToggles::DisablePowerUpSpawns.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HasControl())
			return false;
		if (CoastBoss.State != ECoastBossState::Shooting)
			return false;
		if (!CoastBoss.PowerUpActionQueue.IsEmpty())
			return false;
		if (CoastBoss.bDead)
			return false;
		if (!CoastBoss.bStarted)
			return false;
		if (CoastBoss.GetPhase() == ECoastBossPhase::LerpIn)
			return false;
		if (CoastBoss.GetPhase() == ECoastBossPhase::Phase1)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CoastBoss.PowerUpActionQueue.IsEmpty())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!CoastBossDevToggles::DisablePowerUpSpawns.IsEnabled())
			SpawnPowerUp();
		CoastBoss.PowerUpActionQueue.Idle(Math::RandRange(CoastBossConstants::PowerUp::SpawnIntervalMin, CoastBossConstants::PowerUp::SpawnIntervalMax));
	}
	
	void SpawnPowerUp()
	{
		if (References == nullptr)
		{
			TListedActors<ACoastBossActorReferences> Refs;
			References = Refs.Single;
		}
		FCoastBossSpawnPowerUpActionParams Data;
		Data.SinusOffset = Math::RandRange(0.0, 1.0);
		Data.XOffset = Math::RandRange(0.0, -References.CoastBossPlane2D.PlaneExtents.X * 0.8);	
		CoastBoss.PowerUpActionQueue.Capability(UCoastBossSpawnPowerUpCapability, Data); 
	}
};