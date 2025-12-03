// Use this in the rare cases when you need AI projectiles to sync in network.
// Usually you can get away with using local projectiles without the players noticing.
class UBasicAINetworkedProjectileLauncherComponent : UBasicAIProjectileLauncherComponentBase
{
	UHazeActorNetworkedSpawnPoolComponent SpawnPool;
	TArray<AHazeActor> AvailableProjectiles;
	TArray<AHazeActor> ActiveProjectiles;
	TArray<AHazeActor> IndexedProjectiles;
	int NextProjectileIndex = 0;

 	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		devCheck(ProjectileClass.IsValid(), "" + Owner.Name + " has a projectile launcher component with invalid projectile class. Fix!");
		Wielder = Cast<AHazeActor>(Owner);
		SetupSpawnPool();
	}

	void SetupSpawnPool()
	{
		// Spawn projectiles from a spawn pool, but don't unspawn them until this projectile launcher is destroyed.
		if (SpawnPool != nullptr)	
			return;
		SpawnPool = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(ProjectileClass, Owner);
		SpawnPool.OnSpawnedBySpawner.FindOrAdd(this).AddUFunction(this, n"OnSpawned");	
	}

	// Call this with the number of projectiles you need to have available locally
	void PrepareProjectiles(int NumReservedProjectiles)
	{
		SetupSpawnPool();

		if (!HasControl())
			return;

		int NumToSpawn = NumReservedProjectiles - AvailableProjectiles.Num();
		if (NumToSpawn < 1)
			return;
	
		FHazeActorSpawnParameters Params;
		Params.Spawner = this;
		SpawnPool.SpawnBatchControl(Params, NumToSpawn);

#if !RELEASE
		TEMPORAL_LOG(this).Event("Prepare " + NumToSpawn + " projectiles (on control side only).");		
#endif
	}

	UFUNCTION()
	private void OnSpawned(AHazeActor SpawnedActor, FHazeActorSpawnParameters Params)
	{
		AvailableProjectiles.Add(SpawnedActor);
		IndexedProjectiles.Add(SpawnedActor);
		if (AvailableProjectiles.Num() == 1)
			NextProjectileIndex = IndexedProjectiles.Num() - 1; // We're out of projectiles, next should be this one
		SpawnedActor.AddActorDisable(this);

#if !RELEASE
		TEMPORAL_LOG(this).Event("Spawned projectile, " + AvailableProjectiles.Num() + " available.");		
#endif
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		// Unspawn any projectiles so they can be reused by others
		TArray<AHazeActor> DisabledProjectiles = AvailableProjectiles;
		TArray<AHazeActor> EnabledProjectiles = ActiveProjectiles;
		AvailableProjectiles.Empty();
		ActiveProjectiles.Empty();
		for (AHazeActor Projectile : EnabledProjectiles)
		{
			auto ProjectileComp = UBasicAIProjectileComponent::Get(Projectile); 
			if (ProjectileComp != nullptr)
				ProjectileComp.Expire();
			SpawnPool.UnSpawn(Projectile);
		}
		for (AHazeActor Projectile : DisabledProjectiles)
		{
			SpawnPool.UnSpawn(Projectile);
			Projectile.RemoveActorDisable(this);
		}
	}

	UBasicAIProjectileComponent Launch(FVector Velocity)
	{
		return Launch(Velocity, Velocity.Rotation());
	}

	UBasicAIProjectileComponent Launch(FVector Velocity, FRotator Rotation)
	{
		UBasicAIProjectileComponent Projectile = SpawnProjectile();
		Projectile.Launcher = Wielder;
		Projectile.LaunchingWeapon = this;	
		Projectile.Owner.DetachRootComponentFromParent(true);
		Projectile.AdditionalIgnoreActors = AdditionalProjectileIgnoreActors;
		Projectile.Launch(Velocity, Rotation);
		LastLaunchedProjectile = Projectile;
		OnLaunchProjectile.Broadcast(Projectile);
		return Projectile;
	} 

	UBasicAIProjectileComponent SpawnProjectile()
	{
#if !RELEASE
		TEMPORAL_LOG(this).Event("Launching projectile, index " + NextProjectileIndex + ". " + (AvailableProjectiles.Num() - 1) + " available afterwards.");		
#endif

		if (!ensure((AvailableProjectiles.Num() > 0), "Tried to spawn a projectile which hasn't yet been reserved, will break in network. This is expected if you're tweaking number of projectiles to shoot in a burst, but must otherwiese be preceded by a PrepareProjectiles call."))
		{
			PrepareProjectiles(AvailableProjectiles.Num() + 1);
			NextProjectileIndex = IndexedProjectiles.Num() - 1;
		}

		// To avoid extra netmessages we assume we can reuse projectiles in the same order as they were spawned.	
		int iProj = AvailableProjectiles.FindIndex(IndexedProjectiles[NextProjectileIndex]);
		check(AvailableProjectiles.IsValidIndex(iProj), "Expected projectile has not become available for reuse, will break in network. You need to prepare enough projectiles for the maximum that can be active at any time.");
		NextProjectileIndex = ((NextProjectileIndex + 1) % IndexedProjectiles.Num());

		// Move projectile from reserve to actives and enable
		AHazeActor Projectile = AvailableProjectiles[iProj];
		Projectile.RemoveActorDisable(this);
		AvailableProjectiles.RemoveAtSwap(iProj); 
		ActiveProjectiles.Add(Projectile);

		Projectile.ActorLocation = LaunchLocation;
		Projectile.ActorRotation = WorldRotation;

		FHazeActorSpawnParameters SpawnParams; 
		SpawnParams.Spawner = this;
		SpawnParams.Location = LaunchLocation;
		SpawnParams.Rotation = WorldRotation;

		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::GetOrCreate(Projectile);
		RespawnComp.OnSpawned(Wielder, SpawnParams);
		RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawnedProjectile");

		return UBasicAIProjectileComponent::Get(Projectile);
	}

	UFUNCTION()
	private void OnUnspawnedProjectile(AHazeActor Projectile)
	{
		ActiveProjectiles.Remove(Projectile);
		AvailableProjectiles.Add(Projectile); 

#if !RELEASE
		TEMPORAL_LOG(this).Event("Unspawned projectile for reuse. " + AvailableProjectiles.Num() + " available afterwards.");		
#endif
	}
}


