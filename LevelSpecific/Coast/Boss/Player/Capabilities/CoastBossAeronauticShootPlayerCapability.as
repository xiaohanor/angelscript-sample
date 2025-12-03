struct FCoastBossAeronauticShootPlayerActivateParams
{
	TArray<FCoastBossPlayerBulletData> BulletDatas;
	bool bIsBarrage = false;
}

class UCoastBossAeronauticShootPlayerCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default CapabilityTags.Add(CoastBossTags::CoastBossPlayerShootTag);

	default TickGroup = EHazeTickGroup::Gameplay;

	UCoastBossAeronauticComponent AeroComp;
	UHazeActorLocalSpawnPoolComponent SpawnPool;

	ACoastBossActorReferences References;

	FCoastBossAeronauticShootPlayerActivateParams ActivationParams;
	ACoastBossPlayerBullet PrimedProjectile;
	FHazeActorSpawnParameters SpawnParams;

	TArray<ACoastBossPlayerBullet> UniqueBullets;
	bool bIsInBarrage = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TListedActors<ACoastBossActorReferences> LevelReferencesActor;
		References = LevelReferencesActor.Single;
		AeroComp = UCoastBossAeronauticComponent::GetOrCreate(Owner);
		SpawnPool = HazeActorLocalSpawnPoolStatics::GetOrCreateSpawnPool(AeroComp.PlayerBulletClass, Owner);
		CoastBossDevToggles::BarragePlayerPowerUp.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FCoastBossAeronauticShootPlayerActivateParams& OutParams) const
	{
		if (DeactiveDuration < CoastBossConstants::Player::BulletInterval)
			return false;
		if (AeroComp.AccDashAlpha.Value > KINDA_SMALL_NUMBER)
			return false;
		if (Player.IsPlayerDead())
			return false;
		if (References.Boss.bDead)
			return false;
		
		bool bNormalShoot = IsActioning(ActionNames::PrimaryLevelAbility) || CoastBossDevToggles::AutoShoot.IsEnabled();
		bool bIsWithinPowerUpTime = Time::GameTimeSeconds < AeroComp.LastPowerUpTimestamp + CoastBossConstants::PowerUp::BarragePowerUpDuration;
		bool bHasPowerUp = (bIsWithinPowerUpTime && AeroComp.LastPowerUpType == ECoastBossPlayerPowerUpType::Barrage) || CoastBossDevToggles::BarragePlayerPowerUp.IsEnabled();
		OutParams.bIsBarrage = bHasPowerUp;
		if (!bHasPowerUp && !bNormalShoot)
			return false;

		if (bHasPowerUp)
		{
			float AngleSpan = 30.0;
			int NumBullets = 5;
			float AngleStep = AngleSpan / float(NumBullets);
			float CurrentAngle = AngleSpan * 0.5 * -1.0;
			for (int iBullet = 0; iBullet < NumBullets; ++iBullet)
			{
				FCoastBossPlayerBulletData Data;
				Data.Location = References.CoastBossPlane2D.GetLocationOnPlane(AeroComp.AttachedToShip.ShootLocationComponent.WorldLocation);
				float Y = Math::Sin(Math::DegreesToRadians(CurrentAngle));
				float X = Math::Cos(Math::DegreesToRadians(CurrentAngle));
				FVector2D Direction(X, Y);
				Data.Velocity = Direction * CoastBossConstants::Player::BulletSpeed;
				OutParams.BulletDatas.Add(Data);
				CurrentAngle += AngleStep;
			}
		}
		else
		{
			FCoastBossPlayerBulletData Data;
			Data.Location = References.CoastBossPlane2D.GetLocationOnPlane(AeroComp.AttachedToShip.ShootLocationComponent.WorldLocation);
			Data.Velocity = FVector2D(CoastBossConstants::Player::BulletSpeed, 0.0);
			OutParams.BulletDatas.Add(Data);
		}

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
	void OnActivated(FCoastBossAeronauticShootPlayerActivateParams Params)
	{
		ActivationParams = Params;
		Shoot();

		Player.PlayForceFeedback(AeroComp.FFShoot, false, true, this, Params.bIsBarrage ? 2 : 1);

		if(Params.bIsBarrage && !bIsInBarrage)
		{
			FCoastBossPlayerBulletOnShootParams ShootParams;
			ShootParams.Muzzle = AeroComp.AttachedToShip.ShootLocationComponent;
			UCoastBossAeuronauticPlayerEventHandler::Trigger_OnShootBarrageProjectile(Player, ShootParams);		

			bIsInBarrage = true;
		}
		else if(!Params.bIsBarrage)
		{
			bIsInBarrage = false;
		}
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
			PrimedProjectile.bIsHomingBullet = false;
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
			PrimedProjectile.DamageMultiplier = ActivationParams.bIsBarrage ? CoastBossConstants::PowerUp::BarrageDamageMultiplier : 1.0;
			AeroComp.ActiveBullets.Add(PrimedProjectile);
			UniqueBullets.AddUnique(PrimedProjectile);
			PrimedProjectile.RemoveActorDisable(PrimedProjectile);
			UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::GetOrCreate(PrimedProjectile);
			RespawnComp.OnSpawned(Player, SpawnParams);
			RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawnedProjectile");

			// Do this, otherwise muzzle flash will trigger for each barrage bullet.
			if(iBullet == 0)
			{
				FCoastBossPlayerBulletOnShootParams Params;
				Params.Muzzle = AeroComp.AttachedToShip.ShootLocationComponent;
				UCoastBossPlayerBulletEffectHandler::Trigger_OnShoot(PrimedProjectile, Params);	
			}

			FCoastBossPlayerBulletOnShootParams Params;
			Params.Muzzle = AeroComp.AttachedToShip.ShootLocationComponent;
			if(!ActivationParams.bIsBarrage)
				UCoastBossAeuronauticPlayerEventHandler::Trigger_OnShootBasicProjectile(Player, Params);		

			// if (PrimedProjectile.IsActorDisabledBy(this))
			// 	Debug::DrawDebugSphere(SpawnParams.Location, 100.0, 12, ColorDebug::Magenta, 5.0, 2.0);
			// if (PrimedProjectile.IsActorDisabled())
			// 	Debug::DrawDebugSphere(SpawnParams.Location, 100.0, 12, ColorDebug::Ruby, 5.0, 2.0);
		}

		if(ActivationParams.bIsBarrage)	
		{

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
};