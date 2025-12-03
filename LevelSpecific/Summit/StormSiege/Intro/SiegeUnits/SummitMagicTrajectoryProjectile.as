class ASummitMagicTrajectoryProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent SpiritBallSystem;

	float Speed = 5500.0;
	float LifeTime = 9.0;
	float Gravity = 1000.0;

	FVector Velocity;
	FVector TargetLocation;

	TArray<AActor> IgnoreActors;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		IgnoreActors.Add(this);
		FSummitSpiritBallParams Params;
		Params.Location = ActorLocation;
		USummitSpiritBallEffectHandler::Trigger_MuzzleFlash(this, Params);

		LifeTime += Time::GameTimeSeconds; 

		Velocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(ActorLocation, TargetLocation, Gravity, Speed);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds > LifeTime)
			KillSpiritBall();

		FHitResult Hit;
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
		Trace.UseLine();
		Trace.IgnoreActors(IgnoreActors);
		Trace.DebugDrawOneFrame();
		
		FVector End = ActorLocation + (ActorForwardVector * Speed * DeltaSeconds);
		Hit = Trace.QueryTraceSingle(ActorLocation, End);		

		if (Hit.bBlockingHit)
		{
			ANightQueenMetal Metal = Cast<ANightQueenMetal>(Hit.Actor);
			ASummitNightQueenGem Gem = Cast<ASummitNightQueenGem>(Hit.Actor);

			AActor HitActor = Hit.Actor;
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Hit.Actor);
			if(Player != nullptr)
			{
				HitActor = Player;
			}	
			UPlayerHealthComponent PlayerHealthComp = UPlayerHealthComponent::Get(HitActor);
			if (PlayerHealthComp != nullptr)
				PlayerHealthComp.DamagePlayer(0.2, nullptr, nullptr);		

			if (Metal == nullptr && Gem == nullptr)
				KillSpiritBall();
		}

		Velocity -= FVector(0.0, 0.0, Gravity) * DeltaSeconds;
		ActorLocation += Velocity * DeltaSeconds;
	}

	void KillSpiritBall()
	{
		Timer::SetTimer(this, n"DelayedDestroy", 1.0, false);
		SpiritBallSystem.Deactivate();
		FSummitSpiritBallParams Params;
		Params.Location = ActorLocation;
		USummitSpiritBallEffectHandler::Trigger_Impact(this, Params);
		SetActorTickEnabled(false);
		BP_TEMPHideBall();
	}

	UFUNCTION(BlueprintEvent)
	void BP_TEMPHideBall() {}

	UFUNCTION()
	void DelayedDestroy()
	{
		DestroyActor();
	}
}