class ASanctuaryBossArenaHydraRainProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	float ArcHeight = 0.0;
	float FlightTime = 0.0;
	float FlightDuration = 3.0;
	float Scale = 0.0;
	FVector StartLocation;
	FVector TargetLocation;

	bool bExploded = false;
	int NumFireworks = 0;
	int TargetNumFireworks = 0;

	float FireworkCooldown = 0;
	float MaxFireworkCooldown = 0.2;

	UMedallionPlayerReferencesComponent RefsComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bExploded)
			Move(DeltaSeconds);
	//	else
	//		Fireworks(DeltaSeconds);
	}

	void Move(float DeltaSeconds)
	{
		FlightTime += DeltaSeconds;
		float Alpha = Math::Min(1.0, FlightTime / FlightDuration);

		FVector Location = Math::Lerp(StartLocation, TargetLocation, Alpha);
		Location.Z += Math::Sin(Alpha * PI) * ArcHeight;

		FVector Direction = (Location - ActorLocation).GetSafeNormal(); 
		ActorLocation = Location;
		ActorScale3D = FVector::OneVector + FVector::OneVector * (1.0 - Alpha) * Scale; 

		if (Alpha >= 1.0)
			Explode(Direction);
	}

	void Fireworks(float DeltaSeconds)
	{
		FireworkCooldown -= DeltaSeconds;
		if (FireworkCooldown <= 0.0)
		{
			FireworkCooldown = Math::RandRange(MaxFireworkCooldown * 0.1, MaxFireworkCooldown);
			const float FireworksRadius = 2000.0;
			FVector RandomLocation = ActorLocation;
			RandomLocation.X += Math::RandRange(-FireworksRadius, FireworksRadius);
			RandomLocation.Y += Math::RandRange(-FireworksRadius, FireworksRadius);
			RandomLocation.Z += Math::RandRange(-FireworksRadius, FireworksRadius) * 0.2;
			BP_Explode(RandomLocation);


		}
	}

	void Explode(FVector ProjectileDirection)
	{
		bExploded = true;
		TargetNumFireworks = Math::RandRange(5, 10);
		Root.SetVisibility(false, true);
		Timer::SetTimer(this, n"DelayedDestroy", TargetNumFireworks * MaxFireworkCooldown);
	}

	UFUNCTION()
	void DelayedDestroy()
	{
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Explode(FVector Location)
	{

	}
};