class ASkylineBallBossSmallBossTurret : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TurretRoot;

	UPROPERTY(DefaultComponent, Attach = TurretRoot)
	USceneComponent RotatingTurretRoot;

	UPROPERTY(DefaultComponent, Attach = RotatingTurretRoot)
	USceneComponent ProjectileLocation;

	UPROPERTY(DefaultComponent, Attach = ProjectileLocation)
	UNiagaraComponent MuzzleVFXComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;
	
	UPROPERTY(DefaultComponent, Attach = TurretRoot)
	UGravityBladeCombatTargetComponent BladeTargetComp;
	
	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent BladeResponseComp;

	UPROPERTY()
	UNiagaraSystem ExplosionVFX;

	UPROPERTY()
	UNiagaraSystem LandingVFX;

	UPROPERTY()
	FHazeTimeLike SpawnTimeLike;
	default SpawnTimeLike.UseSmoothCurveZeroToOne();

	UPROPERTY()
	float RotatingSpeed = 90.0;

	UPROPERTY()
	float FireRate = 0.3;

	UPROPERTY()
	float LaunchHeight = 1000.0;

	UPROPERTY()
	TSubclassOf<ASkylineBallBossSmallBossTurretProjectile> ProjectileClass;

	bool bShooting = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SpawnTimeLike.BindUpdate(this, n"SpawnTimeLikeUpdate");
		SpawnTimeLike.BindFinished(this, n"SpawnTimeLikeFinished");
		BladeResponseComp.OnHit.AddUFunction(this, n"HandleBladeHit");

		SpawnTimeLike.Play();
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bShooting)
		{
			RotatingTurretRoot.AddRelativeRotation(FRotator(0.0, RotatingSpeed * DeltaSeconds, 0.0));
		}
	}

	UFUNCTION()
	private void HandleBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{

		HealthComp.TakeDamage(0.4, EDamageType::Default, this);

		if (HealthComp.CurrentHealth <= 0.0)
			Explode();
	}

	UFUNCTION()
	private void Explode()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionVFX, ActorLocation);
		DestroyActor();
	}

	UFUNCTION()
	private void SpawnTimeLikeUpdate(float CurrentValue)
	{
		TurretRoot.SetRelativeLocation(FVector::UpVector * LaunchHeight * CurrentValue);
	}

	UFUNCTION()
	private void SpawnTimeLikeFinished()
	{
		bShooting = true;
		Niagara::SpawnOneShotNiagaraSystemAtLocation(LandingVFX, ActorLocation);
		Timer::SetTimer(this, n"FireProjectile", FireRate, true);
	}

	UFUNCTION()
	private void FireProjectile()
	{
		SpawnActor(ProjectileClass, ProjectileLocation.WorldLocation, ProjectileLocation.WorldRotation);
		MuzzleVFXComp.Activate(true);
	}
};