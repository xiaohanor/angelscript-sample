class AMeltdownSkydiveHomingProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UDamageTriggerComponent DamageTrigger;
	default DamageTrigger.DamageAmount = 0.5;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CamShake;

	UPROPERTY(DefaultComponent)
	UMeltdownGlitchShootingResponseComponent ShootingResponse;

	// Which world to spawn the projectile in
	UPROPERTY(EditAnywhere, Category = "Projectile Spawn")
	EMeltdownPhaseThreeFallingWorld SpawnedWorld;

	// How long after starting to fall in this world should the projectile spawn
	UPROPERTY(EditAnywhere, Category = "Projectile Spawn")
	float SpawnDelay = 0.0;

	// Which player to target. If set to both, randomize. If set to None, go straight up without targeting.
	UPROPERTY(EditAnywhere, Category = "Projectile Targeting")
	EHazeSelectPlayer TargetPlayer;

	// When targeting a player, predict the player's position based on their velocity this much time ahead.
	UPROPERTY(EditAnywhere, Category = "Projectile Targeting")
	float TargetPredictionDuration = 0.0;

	// How much the projectile spins per second
	UPROPERTY(EditAnywhere, Category = "Projectile Movement")
	FRotator ProjectileSpin;

	// How far away from the players should the projectile spawn
	UPROPERTY(EditAnywhere, Category = "Projectile Movement")
	float SpawnDepth = 1500.0;

	// How fast should the projectile approach the players
	UPROPERTY(EditAnywhere, Category = "Projectile Movement")
	float ApproachSpeed = 500.0;

	// How fast should the projectile approach the players
	UPROPERTY(EditAnywhere, Category = "Projectile Movement")
	float ForwardSpeed = 500.0;

	// How fast the projectile's vertical approach should accelerate
	UPROPERTY(EditAnywhere, Category = "Projectile Movement")
	float ApproachAcceleration = 1000.0;

	// Allow the player to destroy the projectile by shooting it
	UPROPERTY(EditAnywhere, Category = "Projectile Destruction")
	bool bAllowDestroyByPlayer = true;

	// How much health the projectile has before it gets destroyed
	UPROPERTY(EditAnywhere, Category = "Projectile Destruction", Meta = (EditCondition = "bAllowDestroyByPlayer"))
	float ProjectileHealth = 5.0;

	// Whether to start the projectile scale small and scale it up to normal size when spawning
	UPROPERTY(EditAnywhere, Category = "Projectile Scaling")
	bool bScaleUpOnSpawn = true;

	// Duration over which to scale up the projectile
	UPROPERTY(EditAnywhere, Category = "Projectile Scaling", Meta = (EditCondition = "bScaleUpOnSpawn"))
	float ScaleUpDuration = 0.5;

	private bool bActive = false;
	private bool bHasSpawned = false;
	private float Timer = 0.0;
	private float Height = 0.0;
	private float VerticalSpeed = 0.0;
	private float HorizontalSpeed = 0.0;
	private float Health = 0.0;
	private FVector StartLocation;
	private FRotator StartRotation;
	private FVector TargetLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DamageTrigger.DisableDamageTrigger(this);
		DamageTrigger.OnPlayerDamagedByTrigger.AddUFunction(this, n"PlayerHit");

		AddActorVisualsBlock(this);
		AddActorCollisionBlock(this);

		ShootingResponse.OnGlitchHit.AddUFunction(this, n"OnHit");
		Health = ProjectileHealth;

		StartLocation = ActorLocation;
		StartRotation = ActorRotation;
	}

	UFUNCTION()
	private void PlayerHit(AHazePlayerCharacter Player)
	{
		auto SkydiveComp = UMeltdownSkydiveComponent::Get(Player);
		SkydiveComp.RequestHitReaction(ActorLocation);
	}

	UFUNCTION()
	private void OnHit(FMeltdownGlitchImpact Impact)
	{
		if (bAllowDestroyByPlayer)
		{
			Health -= Impact.Damage;
			if (Health <= 0.0)
			{
				Despawn();
				DespawnVFX();
			}
		}
	}

	UFUNCTION(BlueprintEvent)
	void DespawnVFX()
	{}

	void Spawn()
	{
		bActive = true;
		bHasSpawned = true;
		Timer = 0.0;

		DamageTrigger.EnableDamageTrigger(this);
		RemoveActorVisualsBlock(this);
		RemoveActorCollisionBlock(this);

		Height = Game::Mio.ActorLocation.Z - SpawnDepth;

		AHazePlayerCharacter Target;
		switch (TargetPlayer)
		{
			case EHazeSelectPlayer::Mio:
				Target = Game::Mio;
			break;
			case EHazeSelectPlayer::Zoe:
				Target = Game::Zoe;
			break;
			case EHazeSelectPlayer::Both:
				if (GetName().Hash % 2 == 0)
					Target = Game::Mio;
				else
					Target = Game::Zoe;
			break;
			case EHazeSelectPlayer::None:
			case EHazeSelectPlayer::Specified:
				Target = nullptr;
			break;
		}

		if (Target == nullptr)
		{
			TargetLocation = StartLocation;
			TargetLocation.Z = Game::Mio.ActorLocation.Z;
		}
		else
		{
			TargetLocation = Target.ActorLocation;
			TargetLocation += Target.ActorHorizontalVelocity * TargetPredictionDuration;
		}

		auto SkydiveSettings = UMeltdownSkydiveSettings::GetSettings(Game::Mio);
		VerticalSpeed = ApproachSpeed - SkydiveSettings.FallingVelocity;
		UpdateLocation();
	}

	void Despawn()
	{
		bActive = false;
		Timer = 0.0;

		DamageTrigger.DisableDamageTrigger(this);
		AddActorVisualsBlock(this);
		AddActorCollisionBlock(this);
	}

	void UpdateLocation()
	{
		float HeightDiff = (Height - TargetLocation.Z);
		float HeightPct = 1.0 - (-HeightDiff / Math::Max(SpawnDepth, 1.0));

		FVector ProjectileLocation = Math::Lerp(StartLocation, TargetLocation, HeightPct);
		ProjectileLocation.Z = Height;

		FRotator ProjectileRotation = StartRotation + ProjectileSpin * Timer;
		SetActorLocationAndRotation(
			ProjectileLocation, ProjectileRotation
		);

		if (bScaleUpOnSpawn)
		{
			FVector WantedScale = FVector(Math::Saturate(Timer / ScaleUpDuration));
			SetActorScale3D(WantedScale);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Check when the projectile should be spawned
		if (!bActive)
		{
			auto SkydiveComp = UMeltdownSkydiveComponent::Get(Game::Mio);
			if (SkydiveComp.CurrentWorld == SpawnedWorld && SkydiveComp.IsSkydiving())
			{
				if (!bHasSpawned)
				{
					Timer += DeltaSeconds;
					if (Timer >= SpawnDelay)
						Spawn();
				}
			}
			else
			{
				bHasSpawned = false;
			}
		}

		if (!bActive)
			return;

		// Move the projectile along the spline
		Timer += DeltaSeconds;
		Height += VerticalSpeed * DeltaSeconds + ApproachAcceleration * 0.5 * Math::Square(DeltaSeconds);
		VerticalSpeed += ApproachAcceleration * DeltaSeconds;

		AddActorLocalOffset(FVector(ForwardSpeed * DeltaSeconds,0,0));

		UpdateLocation();

		if (Height >= TargetLocation.Z + 2000.0)
			Despawn();
	}
};