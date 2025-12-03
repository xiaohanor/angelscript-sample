struct FCoastBossGunShootBallActionParams
{
	TArray<FCoastBossGunBulletData> BulletDatas;
	float CenterAngle = 0.0;
}

class UCoastBossGunShootBallCapability : UHazeActionQueueCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default TickGroup = EHazeTickGroup::Gameplay;

	FCoastBossGunShootBallActionParams QueueParameters;

	ACoastBoss Boss;
	ACoastBossActorReferences References;

	FHazeActorSpawnParameters SpawnParams;
	UHazeActorLocalSpawnPoolComponent SpawnPool;

	int NumSpawnedProjectiles = 0;
	float ShootTimestamp = 0.0;
	bool bHasShot = false;

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
	void OnBecomeFrontOfQueue(FCoastBossGunShootBallActionParams Parameters)
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
		if (!bHasShot)
			return false;
		if (Time::GameTimeSeconds < ShootTimestamp + CoastBossConstants::BigDroneBoss::GunAnticipationDuration)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FCoastBossGunRotateData Data;
		Data.bUseBossPitchRot = false;
		Data.TargetShootAngle = QueueParameters.CenterAngle;
		Data.Prio = ECoastBossGunRotatePrio::Medium;
		Boss.AddRotateReqeuster(this, Data);
		bHasShot = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.RemoveRotateRequester(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bHasShot && Boss.IsGunAligned(QueueParameters.CenterAngle))
		{
			ShootTimestamp = Time::GameTimeSeconds;
			bHasShot = true;
			Shoot();
		}
	}

	void Shoot()
	{
		if (Boss.BulletBallClass == nullptr)
			return;

		FCoastBossEventHandlerSpawnedBulletsData Params;
		Params.GunComponent = Boss.BossMeshComp;
		for (int iData = 0; iData < QueueParameters.BulletDatas.Num(); ++iData)
		{
			FCoastBossGunBulletData Data = QueueParameters.BulletDatas[iData];
			Params.GunSocket = Boss.GetMuzzleSocketName(Data.bUseTopGun, !Data.bUseLeftGun);
			Params.TopMuzzleLocation = Boss.GetMuzzleFlashLocation(true, !Data.bUseLeftGun);
			Params.BotMuzzleLocation = Boss.GetMuzzleFlashLocation(false, !Data.bUseLeftGun);
			SpawnParams.Spawner = this;
			FVector WorldLocation = References.CoastBossPlane2D.GetLocationSnappedToPlane(Boss.GetMuzzleBulletLocation(Data.bUseTopGun, !Data.bUseLeftGun));
			Params.bTopMuzzleFlash = Params.bTopMuzzleFlash || Data.bUseTopGun;
			Params.bBotMuzzleFlash = Params.bBotMuzzleFlash || !Data.bUseTopGun;
			SpawnParams.Location = WorldLocation;
			SpawnParams.Rotation = References.CoastBossPlane2D.GetPlayerHeadingRotation();

			float Y = Math::Sin(Math::DegreesToRadians(Data.ShootAngle));
			float X = -Math::Cos(Math::DegreesToRadians(Data.ShootAngle));
			FVector2D Direction(X, Y);
			FVector2D Velocity = Direction * Data.BulletSpeed;

			ACoastBossBulletBall PrimedProjectile = Cast<ACoastBossBulletBall>(SpawnPool.Spawn(SpawnParams));
			PrimedProjectile.RemoveActorDisable(this);
			PrimedProjectile.SetActorLocationAndRotation(SpawnParams.Location, SpawnParams.Rotation);
			PrimedProjectile.ManualRelativeLocation = References.CoastBossPlane2D.GetLocationOnPlane(PrimedProjectile.ActorLocation);
			PrimedProjectile.Velocity = Velocity;
			PrimedProjectile.Gravity = 0.0;
			PrimedProjectile.bDangerous = true;
			PrimedProjectile.ExtraImpulse.SnapTo(2.5);
			PrimedProjectile.AliveDuration = 0.0;
			PrimedProjectile.BallData.bHitSomething = false;
			PrimedProjectile.TargetScale = PrimedProjectile.BallData.TargetScale;
			PrimedProjectile.AccScale.SnapTo(PrimedProjectile.TargetScale * PrimedProjectile.BallData.InitialScaleMultiplier);
			PrimedProjectile.MeshComp.SetWorldScale3D(FVector::OneVector * 0.1);
			PrimedProjectile.ID = NumSpawnedProjectiles;
			PrimedProjectile.OnSpawned(Boss, References);
			NumSpawnedProjectiles++;
			Boss.ActiveBalls.Add(PrimedProjectile);

			if(Data.bUseLeftGun)
			{
				Boss.LeftGunShootVisualsStartTimeStamp = Time::GameTimeSeconds;
				Boss.bLeftGunShotUp = Data.bUseTopGun;
			}
			else
			{
				Boss.RightGunShootVisualsStartTimeStamp = Time::GameTimeSeconds;
				Boss.bRightGunShotUp = Data.bUseTopGun;
			}

			UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::GetOrCreate(PrimedProjectile);
			RespawnComp.OnSpawned(Boss, SpawnParams);
			RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawnedProjectile");
			Params.Locations.Add(PrimedProjectile.ActorLocation);
			
			//Debug::DrawDebugSphere(SpawnParams.Location, 100.0, 12, ColorDebug::Magenta, 5.0, 2.0);

			if (PrimedProjectile.IsActorDisabledBy(this))
				Debug::DrawDebugSphere(SpawnParams.Location, 100.0, 12, ColorDebug::Magenta, 5.0, 2.0);
			if (PrimedProjectile.IsActorDisabled())
				Debug::DrawDebugSphere(SpawnParams.Location, 100.0, 12, ColorDebug::Ruby, 5.0, 2.0);
		}
		if (Params.Locations.Num() > 0)
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