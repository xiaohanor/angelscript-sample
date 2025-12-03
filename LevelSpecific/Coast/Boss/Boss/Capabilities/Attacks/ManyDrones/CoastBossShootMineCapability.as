struct FCoastBossShootMineActionParams
{
	FCoastBossPlayerBulletData BulletData;
}

class UCoastBossShootMineCapability : UHazeActionQueueCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default TickGroup = EHazeTickGroup::Gameplay;

	FCoastBossShootMineActionParams QueueParameters;

	ACoastBoss Boss;
	ACoastBossActorReferences References;

	FHazeActorSpawnParameters SpawnParams;
	UHazeActorLocalSpawnPoolComponent SpawnPool;
	ACoastBossBulletMine PrimedProjectile;

	bool bTargetMio = false;
	int SpawnedMines = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<ACoastBoss>(Owner);

		if (Boss.BulletMineClass != nullptr)
		{
			SpawnPool = HazeActorLocalSpawnPoolStatics::GetOrCreateSpawnPool(Boss.BulletMineClass, Owner);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FCoastBossShootMineActionParams Parameters)
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
		if (Boss.BulletMineClass != nullptr)
			Prime();
	}

	void Prime()
	{
		SpawnParams.Spawner = this;
		SpawnParams.Location = References.CoastBossPlane2D.GetLocationInWorld(QueueParameters.BulletData.Location);
		SpawnParams.Rotation = References.CoastBossPlane2D.GetPlayerHeadingRotation();
		PrimedProjectile = Cast<ACoastBossBulletMine>(SpawnPool.Spawn(SpawnParams));
		PrimedProjectile.RemoveActorDisable(this);
		PrimedProjectile.SetActorLocationAndRotation(SpawnParams.Location, SpawnParams.Rotation);
		PrimedProjectile.MeshComp.SetVisibility(true);
		PrimedProjectile.ManualRelativeLocation = References.CoastBossPlane2D.GetLocationOnPlane(PrimedProjectile.ActorLocation);
		PrimedProjectile.Velocity = QueueParameters.BulletData.Velocity;
		PrimedProjectile.AliveDuration = 0.0;
		PrimedProjectile.Gravity = 0.0;
		PrimedProjectile.MineData.bPlayerBulletHit = false;
		PrimedProjectile.TargetScale = PrimedProjectile.MineData.TargetScale;
		PrimedProjectile.BeepInterval = PrimedProjectile.SlowBeepInterval;
		PrimedProjectile.BeepCooldown = Math::RandRange(0.0, PrimedProjectile.SlowBeepInterval);
		PrimedProjectile.TargetPlayer = bTargetMio ? Game::Mio : Game::Zoe;
		PrimedProjectile.ID = SpawnedMines;
		PrimedProjectile.Health = CoastBossConstants::BigDroneBoss::Phase3_SunMine_Health;
		SpawnedMines++;
		bTargetMio = !bTargetMio;
		Boss.ActiveMines.Add(PrimedProjectile);
		PrimedProjectile.MineData.bDetonated = false;
		PrimedProjectile.MineData.DetonatedFeedbackDuration = 0.0;
		PrimedProjectile.SetDangerous(true);
		PrimedProjectile.OnSpawn();
		UCoastBossBulletMineEventHandler::Trigger_Spawn(PrimedProjectile);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (Boss.BulletMineClass != nullptr)
			Shoot();
	}

	void Shoot()
	{
		PrimedProjectile.RemoveActorDisable(this);
		PrimedProjectile.SetDangerous(true);
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::GetOrCreate(PrimedProjectile);
		RespawnComp.OnSpawned(Boss, SpawnParams);
		RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawnedProjectile");
		if (PrimedProjectile.IsActorDisabledBy(this))
			Debug::DrawDebugSphere(SpawnParams.Location, 100.0, 12, ColorDebug::Magenta, 5.0, 2.0);
		if (PrimedProjectile.IsActorDisabled())
			Debug::DrawDebugSphere(SpawnParams.Location, 100.0, 12, ColorDebug::Ruby, 5.0, 2.0);
	}

	UFUNCTION()
	private void OnUnspawnedProjectile(AHazeActor Projectile)
	{
		ACoastBossBulletMine Bullet = Cast<ACoastBossBulletMine>(Projectile);
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::GetOrCreate(Bullet);
		RespawnComp.OnUnspawn.Unbind(this, n"OnUnspawnedProjectile");

		Bullet.AliveDuration = 0.0;
		Bullet.AddActorDisable(this);
		{
			Boss.ActiveMines.RemoveSingleSwap(Bullet);
		}
		SpawnPool.UnSpawn(Bullet);
	}

};