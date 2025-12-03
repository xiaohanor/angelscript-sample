struct FWingsuitMineBlockadeLaunchActivatedParams
{
	AWingsuitBossMineBlockadeTargetActor Target;
}

class UWingsuitMineBlockadeLaunchCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(WingsuitBossTags::WingsuitBossAttack);

	default TickGroup = EHazeTickGroup::Gameplay;
	// We want to be before the mine launcher capability so blockades get priority
	default TickGroupOrder = 75;

	AWingsuitBoss Boss;
	UHazeActorNetworkedSpawnPoolComponent SpawnPool;
	UWingsuitBossSettings Settings;

	TArray<AWingsuitBossMineBlockadeTargetActor> QueuedTargets;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<AWingsuitBoss>(Owner);
		SpawnPool = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(Boss.MineBlockadeClass, Boss);
		Settings = UWingsuitBossSettings::GetSettings(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		TListedActors<AWingsuitBossMineBlockadeTargetActor> ListedTargets;
		for(AWingsuitBossMineBlockadeTargetActor Target : ListedTargets.Array)
		{
			if(Target.bConsumed)
				continue;

			float SqrDist = Target.ActorLocation.DistSquared(Boss.ActorLocation);
			if(SqrDist > Math::Square(Target.TriggerRadius))
				continue;

			QueuedTargets.Add(Target);
			Target.bConsumed = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FWingsuitMineBlockadeLaunchActivatedParams& Params) const
	{
		if(!HasControl())
			return false;

		if(QueuedTargets.Num() == 0)
			return false;

		if(!Boss.MineLauncher.IsExtended())
			return false;

		if(Time::GetGameTimeSince(Boss.LastMineSpawnTime) < Settings.ProjectileSpawnCooldown)
			return false;

		Params.Target = QueuedTargets[0];
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FWingsuitMineBlockadeLaunchActivatedParams Params)
	{
		FHazeActorSpawnParameters SpawnParams;
		SpawnParams.Location = Boss.MineLauncher.ShootLocation;
		SpawnParams.Rotation = Boss.MineLauncher.ShootRotation;
		SpawnParams.Spawner = this;
		
		auto CurrentProjectile = Cast<AWingsuitBossBlockadeMine>(SpawnPool.SpawnControl(SpawnParams));

		AWingsuitBossMineBlockadeTargetActor Target = Params.Target;
		QueuedTargets.Remove(Target);
		CrumbOnSpawned(CurrentProjectile, Target);

		Boss.LastMineSpawnTime = Time::GetGameTimeSeconds();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnSpawned(AWingsuitBossBlockadeMine Projectile, AWingsuitBossMineBlockadeTargetActor Target)
	{
		Projectile.SpawnProjectile(Target, SpawnPool, Boss.MineLauncher, Boss.MineLauncher, Settings);
		Projectile.CollisionIgnoreActors = Boss.MineLauncherIgnoreActors;

		Niagara::SpawnOneShotNiagaraSystemAttachedAtLocation(Boss.MineLauncherLaunchEffect, Boss.MineLauncher, Boss.MineLauncher.ShootLocation);
		UWingsuitBossEffectHandler::Trigger_OnShootMine(Boss);
	}
}