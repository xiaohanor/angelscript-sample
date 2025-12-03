class ASanctuaryDodgerProjectile : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;
	default ProjectileComp.Friction = 0.0;
	default ProjectileComp.Gravity = 0.0;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	// After this time we automatically expire
	UPROPERTY()
	float ExpirationTime = 2.0;

	// float DamageAreaLifetime;

	// UPROPERTY(EditAnywhere)
	// TSubclassOf<ASanctuaryDodgerDamageArea> DamageAreaClass;

	// UHazeActorNetworkedSpawnPoolComponent SpawnPool;
	// UHazeActorSpawnPoolReserve SpawnPoolReserve;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// SpawnPool = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(DamageAreaClass, this);
		// SpawnPoolReserve = HazeActorSpawnPoolReserve::Create(this);
		// SpawnPoolReserve.ReserveSpawn(SpawnPool);
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!ProjectileComp.bIsLaunched)
			return;

		// Local movement, should be deterministic(ish)
		FHitResult Hit;
		SetActorLocation(ProjectileComp.GetUpdatedMovementLocation(DeltaTime, Hit));
		if (Hit.bBlockingHit)
		{
			OnImpact(Hit);
			ProjectileComp.Impact(Hit);

			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
			Trace.UseLine();

			// FVector Dir = FVector::UpVector * -1;
			// if(Cast<AHazeCharacter>(Hit.Actor) == nullptr)
			// 	Dir = ProjectileComp.Velocity.GetSafeNormal();

			// FHitResult GeoHit = Trace.QueryTraceSingle(ActorCenterLocation - Dir * 20, ActorCenterLocation + Dir * 500);

			// if(GeoHit.bBlockingHit)
			// {
			// 	ASanctuaryDodgerDamageArea DamageArea = Cast<ASanctuaryDodgerDamageArea>(SpawnPoolReserve.Spawn());
			// 	SpawnPoolReserve.ReserveSpawn(SpawnPool);

			// 	auto DamageAreaRespawnComp = UHazeActorRespawnableComponent::GetOrCreate(DamageArea);
			// 	DamageAreaRespawnComp.OnSpawned(this, FHazeActorSpawnParameters());

			// 	DamageArea.ActorLocation = GeoHit.Location;
			// 	DamageArea.ActorRotation = GeoHit.ImpactNormal.Rotation();
			// 	DamageArea.Launcher = ProjectileComp.Launcher;
			// }
		}

		if (Time::GetGameTimeSince(ProjectileComp.LaunchTime) > ExpirationTime)
			ProjectileComp.Expire();
	}

	// Impact
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FHitResult Hit) {}
}
