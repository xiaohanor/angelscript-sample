struct FCoastBossShootMillActionParams
{
	FCoastBossPlayerBulletData BulletData;
}

class UCoastBossShootMillCapability : UHazeActionQueueCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default TickGroup = EHazeTickGroup::Gameplay;

	FCoastBossShootMillActionParams QueueParameters;

	ACoastBoss Boss;
	ACoastBossActorReferences References;

	FHazeActorSpawnParameters SpawnParams;
	UHazeActorLocalSpawnPoolComponent SpawnPool;
	ACoastBossBulletMill PrimedProjectile;

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
	void OnBecomeFrontOfQueue(FCoastBossShootMillActionParams Parameters)
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
		if (Boss.BulletMillClass != nullptr)
			Prime();
	}

	void Prime()
	{
		SpawnParams.Spawner = this;
		SpawnParams.Location = References.CoastBossPlane2D.GetLocationInWorld(QueueParameters.BulletData.Location);
		SpawnParams.Rotation = References.CoastBossPlane2D.GetPlayerHeadingRotation();
		PrimedProjectile = Cast<ACoastBossBulletMill>(SpawnPool.Spawn(SpawnParams));
		PrimedProjectile.RemoveActorDisable(this);
		PrimedProjectile.SetActorLocationAndRotation(SpawnParams.Location, SpawnParams.Rotation);
		PrimedProjectile.ManualRelativeLocation = References.CoastBossPlane2D.GetLocationOnPlane(PrimedProjectile.ActorLocation);
		PrimedProjectile.Velocity = QueueParameters.BulletData.Velocity;
		PrimedProjectile.AliveDuration = 0.0;
		PrimedProjectile.Gravity = 0.0;
		PrimedProjectile.ScaleValue = 0.0;
		PrimedProjectile.TargetScale = PrimedProjectile.MillData.TargetScale;
		PrimedProjectile.AccScale.SnapTo(KINDA_SMALL_NUMBER);
		Boss.ActiveMills.Add(PrimedProjectile);
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
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (Boss.BulletMillClass != nullptr)
			Shoot();
	}

	void Shoot()
	{
		PrimedProjectile.RemoveActorDisable(this);
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::GetOrCreate(PrimedProjectile);
		RespawnComp.OnSpawned(Boss, SpawnParams);
		RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawnedProjectile");
		UCoastBossBulletMillEventHandler::Trigger_Spawned(PrimedProjectile);
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