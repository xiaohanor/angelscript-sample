class USummitDecimatorTopdownSpearLauncherComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY()
	TSubclassOf<ASummitDecimatorTopdownSpear> ProjectileClass;

	// Seconds in between launched projectiles
	UPROPERTY()
	float LaunchInterval = 2.0;

	UHazeActorLocalSpawnPoolComponent SpawnPool;

 	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		devCheck(ProjectileClass.IsValid(), "" + Owner.Name + " has a Decimator spear launcher component with invalid projectile class. Fix!");

		// We spawn local projectiles in order to reduce number of net messages and code complexity. 
		SpawnPool = HazeActorLocalSpawnPoolStatics::GetOrCreateSpawnPool(ProjectileClass, Owner);
	}

	AHazeActor SpawnProjectile(FVector SpawnLocation)
	{
		FHazeActorSpawnParameters SpawnParams; 
		SpawnParams.Spawner = this;
		SpawnParams.Location = SpawnLocation;
		AHazeActor Projectile = SpawnPool.Spawn(SpawnParams);

		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::GetOrCreate(Projectile);
		RespawnComp.OnSpawned(Owner, SpawnParams);
		RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawnedProjectile");

		return Projectile;
	}

	UFUNCTION()
	private void OnUnspawnedProjectile(AHazeActor Projectile)
	{
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Projectile);
		RespawnComp.OnUnspawn.Unbind(this, n"OnUnspawnedProjectile");
		SpawnPool.UnSpawn(Projectile);
	}

	// TODO: don't need to pass FHitResult, player is enough, or eplosion logic
	// Any significant impacts needs to be networked through us, since projectiles aren't networked
	UFUNCTION(CrumbFunction)
	void CrumbProjectileImpact(FHitResult Hit, float Damage)
	{
		if (Hit.Actor == nullptr)
			return;

		UPlayerHealthComponent PlayerHealthComp = UPlayerHealthComponent::Get(Hit.Actor);
		if (PlayerHealthComp != nullptr)
			PlayerHealthComp.DamagePlayer(Damage, nullptr, nullptr);
	}	

}


