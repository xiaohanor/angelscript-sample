class AMeltdownSkydiveSplineProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent Spline;

	UPROPERTY(DefaultComponent)
	UDamageTriggerComponent DamageTrigger;
	default DamageTrigger.DamageAmount = 0.5;

	UPROPERTY(DefaultComponent)
	UMeltdownGlitchShootingResponseComponent ShootingResponse;

	// Which world to spawn the projectile in
	UPROPERTY(EditAnywhere, Category = "Projectile Spawn")
	EMeltdownPhaseThreeFallingWorld SpawnedWorld;

	// How long after starting to fall in this world should the projectile spawn
	UPROPERTY(EditAnywhere, Category = "Projectile Spawn")
	float SpawnDelay = 0.0;

	// How fast the projectile moves along the spline
	UPROPERTY(EditAnywhere, Category = "Projectile Movement")
	float MovementSpeed = 500.0;

	// How fast the projectile's movement along the spline should accelerate
	UPROPERTY(EditAnywhere, Category = "Projectile Movement")
	float MovementAcceleration = 0.0;

	// How far away from the players should the projectile spawn
	UPROPERTY(EditAnywhere, Category = "Projectile Movement")
	float SpawnDepth = 0.0;

	// How fast should the projectile approach the players
	UPROPERTY(EditAnywhere, Category = "Projectile Movement")
	float ApproachSpeed = 0.0;

	// How fast the projectile's vertical approach should accelerate
	UPROPERTY(EditAnywhere, Category = "Projectile Movement")
	float ApproachAcceleration = 0.0;

	// Whether to rotate the projectile in the forward direction of the spline
	UPROPERTY(EditAnywhere, Category = "Projectile Movement")
	bool bRotateAlongSpline = true;

	// Allow the player to destroy the projectile by shooting it
	UPROPERTY(EditAnywhere, Category = "Projectile Destruction")
	bool bAllowDestroyByPlayer = true;

	// How much health the projectile has before it gets destroyed
	UPROPERTY(EditAnywhere, Category = "Projectile Destruction", Meta = (EditCondition = "bAllowDestroyByPlayer"))
	float ProjectileHealth = 5.0;

	// Whether to start the projectile scale small and scale it up to normal size when spawning
	UPROPERTY(EditAnywhere, Category = "Projectile Scaling")
	bool bScaleUpOnSpawn = false;

	// Duration over which to scale up the projectile
	UPROPERTY(EditAnywhere, Category = "Projectile Scaling", Meta = (EditCondition = "bScaleUpOnSpawn"))
	float ScaleUpDuration = 0.5;

	private bool bActive = false;
	private bool bHasSpawned = false;
	private float SplineDistance = 0.0;
	private float Timer = 0.0;
	private float Height = 0.0;
	private float VerticalSpeed = 0.0;
	private float HorizontalSpeed = 0.0;
	private float Health = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Spline.DetachFromParent(true);

		DamageTrigger.DisableDamageTrigger(this);
		DamageTrigger.OnPlayerDamagedByTrigger.AddUFunction(this, n"PlayerHit");

		AddActorVisualsBlock(this);
		AddActorCollisionBlock(this);

		ShootingResponse.OnGlitchHit.AddUFunction(this, n"OnHit");
		Health = ProjectileHealth;
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

		SplineDistance = 0.0;
		Height = Game::Mio.ActorLocation.Z - SpawnDepth;

		auto SkydiveSettings = UMeltdownSkydiveSettings::GetSettings(Game::Mio);
		VerticalSpeed = ApproachSpeed - SkydiveSettings.FallingVelocity;
		HorizontalSpeed = MovementSpeed;

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
		FTransform SplineTransform = Spline.GetWorldTransformAtSplineDistance(SplineDistance);
		FVector ProjectileLocation = SplineTransform.Location;
		ProjectileLocation.Z = Height;

		FQuat ProjectileRotation = ActorQuat;
		if (bRotateAlongSpline)
			ProjectileRotation = SplineTransform.Rotation;

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
		SplineDistance += HorizontalSpeed * DeltaSeconds + MovementAcceleration * 0.5 * Math::Square(DeltaSeconds);
		Height += VerticalSpeed * DeltaSeconds + ApproachAcceleration * 0.5 * Math::Square(DeltaSeconds);

		HorizontalSpeed += MovementAcceleration * DeltaSeconds;
		VerticalSpeed += ApproachAcceleration * DeltaSeconds;

		UpdateLocation();

		if (SplineDistance >= Spline.SplineLength)
			Despawn();
	}
};