class UBasicAIProjectileLauncherComponentBase : UHazeSkeletalMeshComponentBase
{
	default CollisionProfileName = n"NoCollision";
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY()
	TSubclassOf<AHazeActor> ProjectileClass;

	// Local offset to launch from TODO: Use socket instead when we have separate skeletons
	UPROPERTY()
	FVector LaunchOffset = FVector::ZeroVector;

	UPROPERTY()
	TArray<AActor> AdditionalProjectileIgnoreActors;

	FBasicAIProjectileLaunch OnLaunchProjectile;

	UBasicAIProjectileComponent LastLaunchedProjectile;
	AHazeActor Wielder;

	void SetWielder(AHazeActor NewWielder)
	{
		this.Wielder = NewWielder;
	}

	UFUNCTION(BlueprintPure)
	FVector GetLaunchLocation() const property 
	{
		return WorldTransform.TransformPosition(LaunchOffset);
	}

	UFUNCTION(BlueprintPure)
	AHazeActor GetLauncherActor() const property
	{
		return Cast<AHazeActor>(Owner);
	}
}

class UBasicAIProjectileLauncherComponent : UBasicAIProjectileLauncherComponentBase
{
	// Seconds in between launched projectiles
	UPROPERTY()
	float LaunchInterval = 2.0;

	// For how long the projectile should remain primed until it's launched
	UPROPERTY()
	float PrimeDuration = 0.0;

	// Initial impulse speed of projectiles
	UPROPERTY()
	float LaunchSpeed = 10000.0;

	UPROPERTY()
	UAIFirePatterns FirePatterns;

	FBasicAIProjectilePrime OnPrimeProjectile;

	UBasicAIProjectileComponent PrimedProjectile;
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
		if (PrimedProjectile != nullptr)
			return PrimedProjectile;

		PrimedProjectile = SpawnProjectile();
		PrimedProjectile.Launcher = Wielder;
		PrimedProjectile.LaunchingWeapon = this;	
		PrimedProjectile.Prime();
		PrimedProjectile.Owner.AttachRootComponentTo(this, NAME_None, EAttachLocation::KeepWorldPosition);
		OnPrimeProjectile.Broadcast(PrimedProjectile);
		return PrimedProjectile;
	}

	UBasicAIProjectileComponent Launch(FVector Velocity)
	{
		return Launch(Velocity, Velocity.Rotation());
	}

	UBasicAIProjectileComponent Launch(FVector Velocity, FRotator Rotation)
	{
		UBasicAIProjectileComponent Projectile = PrimedProjectile;
		if (Projectile == nullptr)
			Projectile = SpawnProjectile();
		PrimedProjectile = nullptr;
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
		if (PrimedProjectile != nullptr)
			PrimedProjectile.Expire();
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
	
	// Any significant impacts needs to be networked through us, since projectiles aren't networked
	// This version uses the UDealPlayerDamageComponent to find the mapped damage type asset.
	UFUNCTION(CrumbFunction)
	void CrumbProjectileImpactTypedDamage(FHitResult Hit, float Damage, AHazeActor Launcher, EDamageEffectType DamageEffectType = EDamageEffectType::Generic, EDeathEffectType DeathEffectType = EDeathEffectType::Generic)
	{
		BasicAIProjectile::DealPlayerTypedDamage(Hit, Damage, Launcher, DamageEffectType, DeathEffectType);
	}
}


