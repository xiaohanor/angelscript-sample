class ASkylineBossCarpetBomb : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UGravityBikeWeaponProjectileResponseComponent ProjectileResponseComp;

	UPROPERTY(DefaultComponent)
	UGravityBikeFreeImpactResponseComponent ImpactComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	float FallSpeed = 8000.0;

	float FallingLifeTime = 5.0;
	float DetonationTime = 0.0;
	float DetonationDelay = 12.0;

	bool bHadImpact = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ProjectileResponseComp.OnImpact.AddUFunction(this, n"HandleProjectileImpact");
		ImpactComp.OnImpact.AddUFunction(this, n"HandleBikeImpact");
		UBasicAIHealthBarSettings::SetHealthBarOffset(this, FVector::UpVector * 700.0, this);	
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bHadImpact && GameTimeSinceCreation > FallingLifeTime)
			DestroyActor();

		if (bHadImpact && Time::GameTimeSeconds > DetonationTime)
			Explode();

		if (!bHadImpact)
		{
			FVector DeltaMove = -FVector::UpVector * FallSpeed * DeltaSeconds;

			if (Move(DeltaMove))
				Trigger();
		}
	}

	UFUNCTION()
	private void HandleProjectileImpact(FGravityBikeWeaponImpactData ImpactData)
	{
		HealthComp.TakeDamage(0.25, EDamageType::Default, ImpactData.Instigator);

		if (HealthComp.CurrentHealth <= 0.0)
			Explode();
	}

	UFUNCTION()
	private void HandleBikeImpact(AGravityBikeFree GravityBike, FGravityBikeFreeOnImpactData Data)
	{
		Explode();
	}

	bool Move(FVector DeltaMove)
	{
		FVector Start = ActorLocation;
		FVector End = Start + DeltaMove;
		auto Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnoreActor(this);
		auto HitResult = Trace.QueryTraceSingle(Start, End);

		ActorLocation += DeltaMove * HitResult.Time;

		if (HitResult.bBlockingHit)
			return true;

		return false;
	}

	void Trigger()
	{
		bHadImpact = true;
		DetonationTime = Time::GameTimeSeconds + DetonationDelay;
	}

	void Explode()
	{
		BP_Explode();

		for (auto Player : Game::Players)
		{
			if (Player.GetDistanceTo(this) < 2000.0)
				Player.DamagePlayerHealth(0.9);
		}

		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Explode() { }
};