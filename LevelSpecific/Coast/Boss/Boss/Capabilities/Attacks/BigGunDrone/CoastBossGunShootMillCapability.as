struct FCoastBossGunShootMillActionParams
{
	FCoastBossGunBulletData BulletData;
}

class UCoastBossGunShootMillCapability : UHazeActionQueueCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default TickGroup = EHazeTickGroup::Gameplay;

	FCoastBossGunShootMillActionParams QueueParameters;

	ACoastBoss Boss;
	ACoastBossActorReferences References;

	FHazeActorSpawnParameters SpawnParams;
	UHazeActorLocalSpawnPoolComponent SpawnPool;
	ACoastBossBulletMill PrimedProjectile;

	bool bHasShot = false;
	float ShootTimestamp = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<ACoastBoss>(Owner);

		if (Boss.BulletMillClass != nullptr)
		{
			SpawnPool = HazeActorLocalSpawnPoolStatics::GetOrCreateSpawnPool(Boss.BulletMillClass, Owner);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FCoastBossGunShootMillActionParams Parameters)
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
		Data.TargetShootAngle = QueueParameters.BulletData.ShootAngle;
		Data.Prio = ECoastBossGunRotatePrio::Medium;
		Boss.AddRotateReqeuster(this, Data);
		bHasShot = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.RemoveRotateRequester(this);

		if (!bHasShot)
			Shoot();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bHasShot && Boss.IsGunAligned(QueueParameters.BulletData.ShootAngle))
		{
			ShootTimestamp = Time::GameTimeSeconds;
			bHasShot = true;
			Shoot();		
		}
		if (bHasShot && CoastBossDevToggles::Draw::DrawDebugBoss.IsEnabled())
		{
			FVector WorldVelocity = References.CoastBossPlane2D.GetDirectionInWorld(PrimedProjectile.Velocity);
			Debug::DrawDebugArrow(PrimedProjectile.ActorLocation, PrimedProjectile.ActorLocation + WorldVelocity.GetSafeNormal() * 1000.0, 10.0, ColorDebug::Bubblegum, 5.0, 0.0, true);
		}
	}

	void Shoot()
	{
		if (Boss.BulletMillClass == nullptr)
			return;

		SpawnParams.Spawner = this;
		FVector WorldLocation = References.CoastBossPlane2D.GetLocationSnappedToPlane(Boss.GetMuzzleBulletLocation(QueueParameters.BulletData.bUseTopGun, !QueueParameters.BulletData.bUseLeftGun));

		float Y = Math::Sin(Math::DegreesToRadians(QueueParameters.BulletData.ShootAngle));
		float X = -Math::Cos(Math::DegreesToRadians(QueueParameters.BulletData.ShootAngle));
		FVector2D Direction(X, Y);
		FVector2D Velocity = Direction * QueueParameters.BulletData.BulletSpeed;
		SpawnParams.Location = WorldLocation;
		SpawnParams.Rotation = References.CoastBossPlane2D.GetPlayerHeadingRotation();

		PrimedProjectile = Cast<ACoastBossBulletMill>(SpawnPool.Spawn(SpawnParams));
		PrimedProjectile.RemoveActorDisable(this);
		PrimedProjectile.SetActorLocationAndRotation(SpawnParams.Location, SpawnParams.Rotation);
		PrimedProjectile.ManualRelativeLocation = References.CoastBossPlane2D.GetLocationOnPlane(PrimedProjectile.ActorLocation);
		PrimedProjectile.Velocity = Velocity; 
		PrimedProjectile.AliveDuration = 0.0;
		PrimedProjectile.Gravity = 0.0;
		PrimedProjectile.ExtraImpulse.SnapTo(5.0);
		PrimedProjectile.ScaleValue = 0.0;
		PrimedProjectile.TargetScale = PrimedProjectile.MillData.TargetScale;
		PrimedProjectile.AccScale.SnapTo(KINDA_SMALL_NUMBER);
		Boss.ActiveMills.Add(PrimedProjectile);
		
		Boss.LeftGunShootVisualsStartTimeStamp = Time::GameTimeSeconds;
		Boss.bLeftGunShotUp = QueueParameters.BulletData.bUseTopGun;

		PrimedProjectile.MillData.HitTimes = 0;
		if (PrimedProjectile.MillData.MillBlades.Num() == 0)
		{
			TArray<UStaticMeshComponent> Meshes;
			PrimedProjectile.RootComp.GetChildrenComponentsByClass(UStaticMeshComponent, false, Meshes);
			for (int iMesh = 0; iMesh < Meshes.Num(); ++iMesh)
			{
				if (Meshes[iMesh] != PrimedProjectile.MeshComp)
					PrimedProjectile.MillData.MillBlades.Add(Meshes[iMesh]);
			}
		}

		for (int iBlade = 0; iBlade < PrimedProjectile.MillData.MillBlades.Num(); ++iBlade)
		{
			FVector Scaling = PrimedProjectile.MillData.MillBlades[iBlade].GetWorldScale();
			Scaling.Z = 0.1;
			PrimedProjectile.MillData.MillBlades[iBlade].SetWorldScale3D(Scaling);
		}

		PrimedProjectile.RemoveActorDisable(this);
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::GetOrCreate(PrimedProjectile);
		RespawnComp.OnSpawned(Boss, SpawnParams);
		RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawnedProjectile");
		UCoastBossBulletMillEventHandler::Trigger_Spawned(PrimedProjectile);
		UCoastBossEventHandler::Trigger_SpawnedMill(Boss);

		if (PrimedProjectile.IsActorDisabledBy(this))
			Debug::DrawDebugSphere(SpawnParams.Location, 100.0, 12, ColorDebug::Magenta, 5.0, 2.0);
		if (PrimedProjectile.IsActorDisabled())
			Debug::DrawDebugSphere(SpawnParams.Location, 100.0, 12, ColorDebug::Ruby, 5.0, 2.0);
	}

	UFUNCTION()
	private void OnUnspawnedProjectile(AHazeActor Projectile)
	{
		ACoastBossBulletMill Bullet = Cast<ACoastBossBulletMill>(Projectile);
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::GetOrCreate(Bullet);
		RespawnComp.OnUnspawn.Unbind(this, n"OnUnspawnedProjectile");

		Bullet.AliveDuration = 0.0;
		Bullet.AddActorDisable(this);
		{
			Boss.ActiveMills.RemoveSingleSwap(Bullet);
		}
		SpawnPool.UnSpawn(Bullet);
	}

};