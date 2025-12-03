class UCoastBossAeronauticPlayerLaserPowerUpCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default CapabilityTags.Add(CoastBossTags::CoastBossPowerUp);

	default TickGroup = EHazeTickGroup::Gameplay;

	ACoastBossActorReferences References;
	UCoastBossAeronauticComponent AeroComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TListedActors<ACoastBossActorReferences> LevelReferencesActor;
		References = LevelReferencesActor.Single;
		AeroComp = UCoastBossAeronauticComponent::GetOrCreate(Owner);
		AeroComp.Laser = SpawnActor(AeroComp.PlayerLaserClass);
		AeroComp.Laser.SetActorControlSide(Player);
		AeroComp.Laser.AddActorDisable(this);
		CoastBossDevToggles::LaserPlayerPowerUp.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Player.IsPlayerDead())
			return false;
		if (References.Boss.bDead)
			return false;
		if (!HasPowerUp())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Player.IsPlayerDead())
			return true;
		if (References.Boss.bDead)
			return true;
		if (!HasPowerUp())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CoastBossTags::CoastBossPlayerShootTag, this);
		AeroComp.Laser.AttachToComponent(AeroComp.AttachedToShip.ShootLocationComponent);
		AeroComp.Laser.RemoveActorDisable(this);
		AeroComp.bLaserActive = true;

		Player.PlayForceFeedback(AeroComp.FFLaser, true, true, this);

		FCoastBossPlayerBulletOnShootParams Params;
		Params.Muzzle = AeroComp.AttachedToShip.ShootLocationComponent;
		UCoastBossAeuronauticPlayerEventHandler::Trigger_OnPlayerLaserActivated(Player, Params);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CoastBossTags::CoastBossPlayerShootTag, this);
		AeroComp.Laser.AddActorDisable(this);
		AeroComp.bLaserActive = false;
		Player.StopForceFeedback(this);

		if(AeroComp.Laser.bCurrentlyHittingCoastBoss)
		{
			FCoastBossPlayerLaserStopImpactingEffectParams Params;
			Params.PlaneToAttachTo = References.CoastBossPlane2D.Root;
			UCoastBossPlayerLaserEffectHandler::Trigger_OnStopImpactingCoastBoss(AeroComp.Laser, Params);
			AeroComp.Laser.bCurrentlyHittingCoastBoss = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AeroComp.Laser.ActorRotation = FRotator::MakeFromZX(FVector::UpVector, References.CoastBossPlane2D.ActorRightVector);
	}

	bool HasPowerUp() const
	{
		if(CoastBossDevToggles::LaserPlayerPowerUp.IsEnabled())
			return true;

		if(Time::GetGameTimeSince(AeroComp.LastPowerUpTimestamp) > CoastBossConstants::PowerUp::LaserPowerUpDuration)
			return false;

		if(AeroComp.LastPowerUpType != ECoastBossPlayerPowerUpType::Laser)
			return false;

		return true;
	}
}