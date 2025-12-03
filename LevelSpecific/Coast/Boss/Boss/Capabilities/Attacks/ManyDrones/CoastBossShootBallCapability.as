struct FCoastBossShootBallActionParams
{
	TArray<FCoastBossPlayerBulletData> BulletDatas;
}

class UCoastBossShootBallCapability : UHazeActionQueueCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default TickGroup = EHazeTickGroup::Gameplay;

	FCoastBossShootBallActionParams QueueParameters;

	ACoastBoss Boss;
	ACoastBossActorReferences References;

	FHazeActorSpawnParameters SpawnParams;
	UHazeActorLocalSpawnPoolComponent SpawnPool;
	TArray<ACoastBossBulletBall> PrimedProjectiles;
	int NumSpawnedProjectiles = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<ACoastBoss>(Owner);
		if (Boss.BulletBallClass != nullptr)
		{
			SpawnPool = HazeActorLocalSpawnPoolStatics::GetOrCreateSpawnPool(Boss.BulletBallClass, Owner);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FCoastBossShootBallActionParams Parameters)
	{
		QueueParameters = Parameters;
		if (References == nullptr)
		{
			TListedActors<ACoastBossActorReferences> Refs;
			References = Refs.Single;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
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
	void OnActivated()
	{
		if (Boss.BulletBallClass != nullptr)
			Prime();
	}

	void Prime()
	{
		for (int iData = 0; iData < QueueParameters.BulletDatas.Num(); ++iData)
		{
			FCoastBossPlayerBulletData Data = QueueParameters.BulletDatas[iData];
			SpawnParams.Spawner = this;
			SpawnParams.Location = References.CoastBossPlane2D.GetLocationInWorld(Data.Location);
			SpawnParams.Rotation = References.CoastBossPlane2D.GetPlayerHeadingRotation();
			ACoastBossBulletBall PrimedProjectile = Cast<ACoastBossBulletBall>(SpawnPool.Spawn(SpawnParams));
			PrimedProjectile.RemoveActorDisable(this);
			PrimedProjectile.SetActorLocationAndRotation(SpawnParams.Location, SpawnParams.Rotation);
			PrimedProjectile.ManualRelativeLocation = References.CoastBossPlane2D.GetLocationOnPlane(PrimedProjectile.ActorLocation);
			PrimedProjectile.Velocity = Data.Velocity;
			PrimedProjectile.Gravity = 0.0;
			PrimedProjectile.bDangerous = true;
			PrimedProjectile.AliveDuration = 0.0;
			PrimedProjectile.BallData.bHitSomething = false;
			PrimedProjectile.TargetScale = PrimedProjectile.BallData.TargetScale;
			PrimedProjectile.AccScale.SnapTo(PrimedProjectile.TargetScale * PrimedProjectile.BallData.InitialScaleMultiplier);
			PrimedProjectile.MeshComp.SetWorldScale3D(FVector::OneVector * 0.1);
			PrimedProjectile.ID = NumSpawnedProjectiles;
			PrimedProjectile.OnSpawned(Boss, References);
			NumSpawnedProjectiles++;
			Boss.ActiveBalls.Add(PrimedProjectile);
			PrimedProjectiles.Add(PrimedProjectile);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (Boss.BulletBallClass != nullptr)
			Shoot();
	}

	void Shoot()
	{
		FCoastBossEventHandlerSpawnedBulletsData Params;
		Params.GunComponent = Boss.BossMeshComp;
		Params.GunSocket = n"LeftGunArm";
		Params.TopMuzzleLocation = Boss.GetMuzzleFlashLocation(true, false);
		Params.BotMuzzleLocation = Boss.GetMuzzleFlashLocation(false, false);
		for (int iBullet = 0; iBullet < PrimedProjectiles.Num(); ++iBullet)
		{
			ACoastBossBulletBall PrimedProjectile = PrimedProjectiles[iBullet];
			PrimedProjectile.RemoveActorDisable(this);
			UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::GetOrCreate(PrimedProjectile);
			Params.bTopMuzzleFlash = Params.bTopMuzzleFlash || true;
			RespawnComp.OnSpawned(Boss, SpawnParams);
			RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawnedProjectile");
			Params.Locations.Add(PrimedProjectile.ActorLocation);
			if (PrimedProjectile.IsActorDisabledBy(this))
				Debug::DrawDebugSphere(SpawnParams.Location, 100.0, 12, ColorDebug::Magenta, 5.0, 2.0);
			if (PrimedProjectile.IsActorDisabled())
				Debug::DrawDebugSphere(SpawnParams.Location, 100.0, 12, ColorDebug::Ruby, 5.0, 2.0);
		}
		UCoastBossEventHandler::Trigger_SpawnedBullets(Boss, Params);
	}

	UFUNCTION()
	private void OnUnspawnedProjectile(AHazeActor Projectile)
	{
		ACoastBossBulletBall Bullet = Cast<ACoastBossBulletBall>(Projectile);
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::GetOrCreate(Bullet);
		RespawnComp.OnUnspawn.Unbind(this, n"OnUnspawnedProjectile");

		Bullet.AliveDuration = 0.0;
		Bullet.AddActorDisable(this);
		{
			Boss.ActiveBalls.Remove(Bullet);
		}
		SpawnPool.UnSpawn(Bullet);
	}

};