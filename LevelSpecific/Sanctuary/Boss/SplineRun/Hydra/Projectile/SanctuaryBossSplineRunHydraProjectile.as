class ASanctuaryBossSplineRunHydraProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSphereComponent HazeSphereComp;

	UPROPERTY(DefaultComponent, Attach = HazeSphereComp)
	USpotLightComponent SpotLightComp;

	float ArcHeight = 2000.0;
	float FlightTime = 0.0;
	float FlightDuration = 3.0;
	float GrowingScale = 1.0;
	float DamageRadius = 200.0;
	FVector StartLocation;
	FVector TargetLocation;

	ASanctuaryBossSplineRunHydraProjectileTarget ProjectileTarget;

	FVector TargetOffset;

	UPROPERTY()
	FHazeTimeLike TelegraphTimeLike;
	default TelegraphTimeLike.Duration = 2.0;
	default TelegraphTimeLike.UseSmoothCurveZeroToOne();

	float HazeSphereMaxOpacity = 1.0;
	float HazeSphereOpacityFadeSpeed = 0.1;
	float HazeSphereOpacity = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (ProjectileTarget == nullptr)
		{
			DestroyActor();
			return;
		}

		
		FlightTime += DeltaSeconds;
		float Alpha = Math::Min(1.0, FlightTime / FlightDuration);

		TargetLocation = ProjectileTarget.ActorLocation + TargetOffset;

		FVector Location = Math::Lerp(StartLocation, TargetLocation, Alpha);
		Location.Z += Math::Sin(Alpha * PI) * ArcHeight;

		FVector Direction = (Location - ActorLocation).GetSafeNormal(); 

		ActorLocation = Location;
		ActorScale3D = FVector::OneVector; 

		HazeSphereOpacity += HazeSphereOpacityFadeSpeed * DeltaSeconds;
		HazeSphereOpacity = Math::Min(HazeSphereOpacity, HazeSphereMaxOpacity);
		HazeSphereComp.SetOpacityValue(HazeSphereOpacity);

		SpotLightComp.SetIntensity(Math::Lerp(0.0, 50.0, HazeSphereOpacity / HazeSphereMaxOpacity));

		HazeSphereComp.SetWorldLocation(TargetLocation);

		// ActorScale3D = FVector::OneVector + FVector::OneVector * (1.0 - Alpha) * 0.0; 
		if (Alpha >= 1.0)
			Explode(Direction);
	}

	void Explode(FVector ProjectileDirection)
	{
		for (auto Player : Game::Players)
		{
			if (Player.GetDistanceTo(this) < DamageRadius)
				Player.DamagePlayerHealth(0.4);
		}

		BP_Explode();

		if (ProjectileTarget != nullptr && ProjectileTarget.AttachParentActor != nullptr)
		{
			ASanctuaryBossSplineRunPlatform ParentPlatform = Cast<ASanctuaryBossSplineRunPlatform>(ProjectileTarget.AttachParentActor);
			//if (ParentPlatform != nullptr)
				//FauxPhysics::ApplyFauxImpulseToActorAt(ParentPlatform, TargetLocation, FVector::UpVector * -600.0);
		}

		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Explode()
	{
	}
};