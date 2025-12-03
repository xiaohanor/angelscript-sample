struct FCoastBossAeronauticShootHomingPlayerActivateParams
{
	TArray<FCoastBossPlayerBulletData> BulletDatas;
}

class UCoastBossAeronauticShootHomingPlayerCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default CapabilityTags.Add(CoastBossTags::CoastBossPlayerShootTag);
	default CapabilityTags.Add(CoastBossTags::CoastBossPowerUp);
	default BlockExclusionTags.Add(CoastBossTags::CoastBossPowerUp);

	default TickGroup = EHazeTickGroup::Gameplay;

	UCoastBossAeronauticComponent AeroComp;
	UHazeActorLocalSpawnPoolComponent SpawnPool;

	ACoastBossActorReferences References;

	FCoastBossAeronauticShootHomingPlayerActivateParams ActivationParams;
	ACoastBossPlayerBullet PrimedProjectile;
	FHazeActorSpawnParameters SpawnParams;

	TArray<ACoastBossPlayerBullet> UniqueBullets;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TListedActors<ACoastBossActorReferences> LevelReferencesActor;
		References = LevelReferencesActor.Single;
		AeroComp = UCoastBossAeronauticComponent::GetOrCreate(Owner);
		SpawnPool = HazeActorLocalSpawnPoolStatics::GetOrCreateSpawnPool(AeroComp.PlayerHomingBulletClass, Owner);
		CoastBossDevToggles::BarragePlayerPowerUp.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FCoastBossAeronauticShootHomingPlayerActivateParams& OutParams) const
	{
		if (DeactiveDuration < CoastBossConstants::PowerUp::HomingBulletInterval)
			return false;
		if (AeroComp.AccDashAlpha.Value > KINDA_SMALL_NUMBER)
			return false;
		if (Player.IsPlayerDead())
			return false;
		if (References.Boss.bDead)
			return false;
		if(!HasPowerUp())
			return false;
		
		bool bNormalShoot = IsActioning(ActionNames::PrimaryLevelAbility) || CoastBossDevToggles::AutoShoot.IsEnabled();
		if (!bNormalShoot)
			return false;

		FCoastBossPlayerBulletData Data;
		Data.Location = References.CoastBossPlane2D.GetLocationOnPlane(AeroComp.AttachedToShip.ShootLocationComponent.WorldLocation);
		Data.Velocity = FVector2D(CoastBossConstants::PowerUp::HomingBulletSpeed, 0.0);
		OutParams.BulletDatas.Add(Data);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration < KINDA_SMALL_NUMBER)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCoastBossAeronauticShootHomingPlayerActivateParams Params)
	{
		ActivationParams = Params;
		Shoot();
		Player.PlayForceFeedback(AeroComp.FFHoming, false, true, this);
	}

	void Shoot()
	{
		for (int iBullet = 0; iBullet < ActivationParams.BulletDatas.Num(); ++iBullet)
		{
			FCoastBossPlayerBulletData Data = ActivationParams.BulletDatas[iBullet];
			SpawnParams.Spawner = this;
			SpawnParams.Location = References.CoastBossPlane2D.GetLocationInWorld(Data.Location);
			SpawnParams.Rotation = References.CoastBossPlane2D.GetPlayerHeadingRotation();
			PrimedProjectile = Cast<ACoastBossPlayerBullet>(SpawnPool.Spawn(SpawnParams));
			PrimedProjectile.SetActorControlSide(Player);
			PrimedProjectile.bIsHomingBullet = true;
			PrimedProjectile.SetActorLocationAndRotation(SpawnParams.Location, SpawnParams.Rotation);
			PrimedProjectile.SetActorScale3D(FVector::OneVector);
			PrimedProjectile.ManualRelativeLocation = References.CoastBossPlane2D.GetLocationOnPlane(PrimedProjectile.ActorLocation);
			PrimedProjectile.Velocity = Data.Velocity;
			PrimedProjectile.AliveDuration = 0.0;
			PrimedProjectile.bShouldDespawn = false;
			PrimedProjectile.HitActors.Reset();
			PrimedProjectile.Gravity = 0.0;
			PrimedProjectile.Scale = 1.0;
			PrimedProjectile.TargetScale = 1.0;
			AeroComp.ActiveBullets.Add(PrimedProjectile);
			UniqueBullets.AddUnique(PrimedProjectile);
			PrimedProjectile.RemoveActorDisable(PrimedProjectile);
			UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::GetOrCreate(PrimedProjectile);
			RespawnComp.OnSpawned(Player, SpawnParams);
			RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawnedProjectile");
			
			FCoastBossPlayerBulletOnShootParams Params;
			Params.Muzzle = AeroComp.AttachedToShip.ShootLocationComponent;
			UCoastBossPlayerBulletEffectHandler::Trigger_OnShoot(PrimedProjectile, Params);
			UCoastBossAeuronauticPlayerEventHandler::Trigger_OnShootHomingProjectile(Player, Params);

			// if (PrimedProjectile.IsActorDisabledBy(this))
			// 	Debug::DrawDebugSphere(SpawnParams.Location, 100.0, 12, ColorDebug::Magenta, 5.0, 2.0);
			// if (PrimedProjectile.IsActorDisabled())
			// 	Debug::DrawDebugSphere(SpawnParams.Location, 100.0, 12, ColorDebug::Ruby, 5.0, 2.0);
		}
	}

	UFUNCTION()
	private void OnUnspawnedProjectile(AHazeActor Projectile)
	{
		ACoastBossPlayerBullet Bullet = Cast<ACoastBossPlayerBullet>(Projectile);
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::GetOrCreate(Bullet);
		RespawnComp.OnUnspawn.Unbind(this, n"OnUnspawnedProjectile");
		{
			AeroComp.ActiveBullets.Remove(Bullet);
		}
		SpawnPool.UnSpawn(Bullet);
	}

	bool HasPowerUp() const
	{
		if(CoastBossDevToggles::HomingPlayerPowerUp.IsEnabled())
			return true;

		if(Time::GetGameTimeSince(AeroComp.LastPowerUpTimestamp) > CoastBossConstants::PowerUp::HomingPowerUpDuration)
			return false;

		if(AeroComp.LastPowerUpType != ECoastBossPlayerPowerUpType::Homing)
			return false;

		return true;
	}
}