class UWingsuitBossMineLauncherCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(WingsuitBossTags::WingsuitBossAttack);

	default TickGroup = EHazeTickGroup::Gameplay;

	int ProjectilesFiredInThisBurst = 0;
	AWingsuitBoss Boss;
	UHazeActorNetworkedSpawnPoolComponent SpawnPool;
	UWingsuitBossSettings Settings;
	AWingsuitBossMine CurrentProjectile;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<AWingsuitBoss>(Owner);
		SpawnPool = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(Boss.MineClass, Boss);
		Settings = UWingsuitBossSettings::GetSettings(Boss);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;

		if(!Boss.bWeaponsActive)
			return false;

		if(!Boss.MineLauncher.IsExtended())
			return false;

		if(CurrentProjectile != nullptr && !CurrentProjectile.bHasBeenShot)
			return false;

		float CurrentCooldown = ProjectilesFiredInThisBurst == 2 ? Settings.ProjectileSpawnCooldownBetweenBursts : Settings.ProjectileSpawnCooldown;
		if(Time::GetGameTimeSince(Boss.LastMineSpawnTime) < CurrentCooldown + Settings.ProjectileDurationFromSpawnToShoot)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(ProjectilesFiredInThisBurst == 2)
			ProjectilesFiredInThisBurst = 0;

		AHazePlayerCharacter Player = ProjectilesFiredInThisBurst == 0 ? Game::Mio : Game::Zoe;

		FHazeActorSpawnParameters SpawnParams;
		SpawnParams.Location = Boss.MineLauncher.ShootLocation;
		SpawnParams.Rotation = FRotator::MakeFromZX(FVector::UpVector, Player.ActorLocation - Boss.MineLauncher.ShootLocation);
		SpawnParams.Spawner = this;
		
		CurrentProjectile = Cast<AWingsuitBossMine>(SpawnPool.SpawnControl(SpawnParams));

		CrumbOnSpawned(CurrentProjectile, Player);

		Boss.LastMineSpawnTime = Time::GetGameTimeSeconds();
		++ProjectilesFiredInThisBurst;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnSpawned(AWingsuitBossMine Projectile, AHazePlayerCharacter Player)
	{
		Projectile.SpawnProjectile(Player, SpawnPool, Boss.MineLauncher, Boss.MineLauncher, Settings);
		Projectile.CollisionIgnoreActors = Boss.MineLauncherIgnoreActors;

		Niagara::SpawnOneShotNiagaraSystemAttachedAtLocation(Boss.MineLauncherLaunchEffect, Boss.MineLauncher, Boss.MineLauncher.ShootLocation);
		UWingsuitBossEffectHandler::Trigger_OnShootMine(Boss);
	}
}