// mostly copied from UBasicAIProjectileLauncherComponent
class USanctuaryGrimbeastMultiBoulderLauncherComponent : UBasicAIProjectileLauncherComponentBase
{
	FBasicAIProjectilePrime OnPrimeProjectile;

	TArray<UBasicAIProjectileComponent> PrimedProjectilesQueue;
	UHazeActorLocalSpawnPoolComponent SpawnPool;

 	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		devCheck(ProjectileClass.IsValid(), "" + Owner.Name + " has a projectile launcher component with invalid projectile class. Fix!");
		Wielder = Cast<AHazeActor>(Owner);

		// We spawn local projectiles in order to reduce number of net messages and code complexity. 
		SpawnPool = HazeActorLocalSpawnPoolStatics::GetOrCreateSpawnPool(ProjectileClass, Owner);
	}

	UBasicAIProjectileComponent Prime()
	{
		UBasicAIProjectileComponent PrimedProjectile = SpawnProjectile();
		PrimedProjectile.Launcher = Wielder;
		PrimedProjectile.LaunchingWeapon = this;	
		PrimedProjectile.Prime();
		PrimedProjectile.Owner.AttachRootComponentTo(this, NAME_None, EAttachLocation::KeepWorldPosition);
		OnPrimeProjectile.Broadcast(PrimedProjectile);
		PrimedProjectilesQueue.Add(PrimedProjectile);
		return PrimedProjectile;
	}

	UBasicAIProjectileComponent Launch(FVector Velocity)
	{
		return Launch(Velocity, Velocity.Rotation());
	}

	UBasicAIProjectileComponent Launch(FVector Velocity, FRotator Rotation)
	{
		UBasicAIProjectileComponent Projectile = PopFirst();
		if (Projectile == nullptr)
			Projectile = SpawnProjectile();
		Projectile.Launcher = Wielder;
		Projectile.LaunchingWeapon = this;	
		Projectile.Owner.DetachRootComponentFromParent(true);
		Projectile.AdditionalIgnoreActors = AdditionalProjectileIgnoreActors;
		Projectile.Launch(Velocity, Rotation);
		LastLaunchedProjectile = Projectile;
		OnLaunchProjectile.Broadcast(Projectile);
		return Projectile;
	} 

	void DeactivateLauncher()
	{
		for (int i = 0; i < PrimedProjectilesQueue.Num(); i++) 
			PrimedProjectilesQueue[i].Expire();
		PrimedProjectilesQueue.Empty();
	}

	UBasicAIProjectileComponent PopFirst()
	{
		if (PrimedProjectilesQueue.Num() == 0)
			Prime();
		UBasicAIProjectileComponent First = PrimedProjectilesQueue[0];
		PrimedProjectilesQueue.RemoveAt(0);
		return First;
	}

	UBasicAIProjectileComponent SpawnProjectile()
	{
		FHazeActorSpawnParameters SpawnParams; 
		SpawnParams.Spawner = this;
		SpawnParams.Location = LaunchLocation;
		SpawnParams.Rotation = WorldRotation;
		AHazeActor Projectile = SpawnPool.Spawn(SpawnParams);

		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::GetOrCreate(Projectile);
		RespawnComp.OnSpawned(Wielder, SpawnParams);
		RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawnedProjectile");

		return UBasicAIProjectileComponent::Get(Projectile);
	}

	UFUNCTION()
	private void OnUnspawnedProjectile(AHazeActor Projectile)
	{
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Projectile);
		RespawnComp.OnUnspawn.Unbind(this, n"OnUnspawnedProjectile");
		SpawnPool.UnSpawn(Projectile);
	}

	// Any significant impacts needs to be networked through us, since projectiles aren't networked
	UFUNCTION(CrumbFunction)
	void CrumbProjectileImpact(FHitResult Hit, float Damage, EDamageType DamageType, AHazeActor Launcher)
	{
		BasicAIProjectile::DealDamage(Hit, Damage, DamageType, Launcher);
	}	
}


