class ASummitMageCritterSlug : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent SpiritBallSystem;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;
	default ProjectileComp.Friction = 0.01;
	default ProjectileComp.Gravity = 9.82;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"HazeActorSpawnerCapability");

	UPROPERTY(DefaultComponent)
	UHazeActorSpawnerComponent SpawnerComp;

	UPROPERTY(DefaultComponent)
	USummitMageCritterSpawnPattern SpawnPattern;

	UPROPERTY(DefaultComponent)
	UAcidResponseComponent AcidResponseComp;

	UPROPERTY(DefaultComponent)
	USummitMagePlateComponent PlateComp;

	float Speed = 2500.0;

	float LifeTime = 0.0;
	float LifeDuration = 6.0;

	private float SpawnDelayDuration = 2;
	private float SpawnDelayTime;
	private bool bSpawned;

	TArray<AActor> IgnoreActors;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		IgnoreActors.Add(this);
		FSummitSpiritBallParams Params;
		Params.Location = ActorLocation;
		USummitSpiritBallEffectHandler::Trigger_MuzzleFlash(this, Params);

		LifeTime = Time::GetGameTimeSeconds();

		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		ProjectileComp.Expire();
	}

	UFUNCTION()
	private void OnReset()
	{
		LifeTime = Time::GetGameTimeSeconds();
		SpawnDelayTime = 0;
		bSpawned = false;
		SpawnerComp.DeactivateSpawner(this);
		SpawnPattern.bDoneSpawning = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(SpawnDelayTime != 0)
		{
			if(!bSpawned && Time::GetGameTimeSince(SpawnDelayTime) > SpawnDelayDuration)
			{
				Spawn();
				bSpawned = true;
			}

			if(SpawnPattern.bDoneSpawning)
				ProjectileComp.Expire();
			
			return;
		}

		if (Time::GetGameTimeSince(LifeTime) > LifeDuration)
			ProjectileComp.Expire();

		FHitResult Hit;
		SetActorLocation(ProjectileComp.GetUpdatedMovementLocation(DeltaSeconds, Hit));
		if (Hit.bBlockingHit)
		{
			PlayerHit(Hit);
			SpawnerHit(Hit);
			FSummitSpiritBallParams Params;
			Params.Location = ActorLocation;
			USummitSpiritBallEffectHandler::Trigger_Impact(this, Params);			
		}

		SetActorRotation(ProjectileComp.Velocity.Rotation());
	}

	void PlayerHit(FHitResult Hit)
	{
		AActor HitActor = Hit.Actor;
		AHazePlayerCharacter Dragon = Cast<AHazePlayerCharacter>(Hit.Actor);
		if(Dragon != nullptr)
			HitActor = Dragon;

		auto DragonComp = UPlayerTeenDragonComponent::Get(HitActor);
		if(DragonComp != nullptr)
		{
			FVector Dir = (HitActor.ActorLocation - ActorLocation).GetSafeNormal2D();
			Dir.Z = 0.75;
			Dragon.AddMovementImpulse(Dir * 1000);
		}
	}

	void SpawnerHit(FHitResult Hit)
	{
		SpawnDelayTime = Time::GetGameTimeSeconds();
	}

	void Spawn()
	{
		SpawnPattern.SpawnLocation = ActorLocation + ActorUpVector * 500;
		SpawnerComp.ActivateSpawner(this);
	}
}