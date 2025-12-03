class AMeltdownGlitchBeam : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BeamMesh;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent BeamEffect;

	bool bStarted = false;
	bool bStopped = false;
	float StopTimer = 0.0;

	AHazePlayerCharacter OwningPlayer;
	float DamageInterval = 0.1;
	float Damage = 1.0;

	float Distance = 0.0;
	float Speed = 10000;
	float Acceleration = 50000;
	float MaxDistance = 15000;

	float HitTimer = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	void StartBeam()
	{
		bStarted = true;
	}

	void UpdateBeam(FVector StartLocation, FVector BeamDirection)
	{
		FTransform NewTransform;
		NewTransform.SetLocation(StartLocation);
		NewTransform.SetRotation(FQuat::MakeFromX(BeamDirection));
		NewTransform.SetScale3D(FVector(Distance / 100, 1, 1));

		SetActorTransform(NewTransform);
	}

	void StopBeam()
	{
		bStopped = true;
		BeamMesh.SetHiddenInGame(true);
		BeamEffect.Deactivate();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bStarted)
			return;

		if (bStopped)
		{
			StopTimer += DeltaSeconds;
			if (StopTimer > 0.5)
				DestroyActor();
			return;
		}

		Speed += Acceleration * DeltaSeconds;
		Distance = Math::Min(MaxDistance, Distance + Speed * DeltaSeconds);

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::PlayerAiming);
		Trace.UseLine();
		Trace.SetReturnPhysMaterial(true);

		FHitResult Hit = Trace.QueryTraceSingle(ActorLocation, ActorLocation + ActorForwardVector * Distance);

		HitTimer += DeltaSeconds;
		if (HitTimer > DamageInterval && Hit.bBlockingHit)
		{
			HitTimer -= DamageInterval;

			TArray<UMeltdownGlitchShootingResponseComponent> ResponseComps;
			Hit.Actor.GetComponentsByClass(UMeltdownGlitchShootingResponseComponent, ResponseComps);

			FMeltdownGlitchImpact Impact;
			Impact.FiringPlayer = OwningPlayer;
			Impact.ImpactPoint = Hit.ImpactPoint;
			Impact.ImpactNormal = Hit.ImpactNormal;
			Impact.Damage = Damage;
			Impact.ProjectileDirection = ActorForwardVector;

			for (auto ResponseComp : ResponseComps)
				ResponseComp.TriggerGlitchHit(Impact);

			FMeltdownGlitchProjectileImpactEffectParams HitEffectParams;
			HitEffectParams.ResponseComponents = ResponseComps;
			HitEffectParams.ImpactPoint = Hit.ImpactPoint;
			HitEffectParams.ImpactNormal = Hit.ImpactNormal;
			HitEffectParams.PhysMat = Hit.PhysMaterial;
			HitEffectParams.ProjectileLocation = ActorLocation;
			UMeltdownGlitchShootingProjectileEffectHandler::Trigger_OnProjectileHit(this, HitEffectParams);
		}

		FVector BeamEndLocation;
		if (Hit.bBlockingHit)
		{
			BeamEndLocation = Hit.ImpactPoint;
		}
		else
		{
			BeamEndLocation = ActorLocation + ActorForwardVector * Distance;
		}

		BeamEffect.SetVectorParameter(n"BeamStart", ActorLocation);
		BeamEffect.SetVectorParameter(n"BeamEnd", BeamEndLocation);
		// Debug::DrawDebugLine(ActorLocation, BeamEndLocation, FLinearColor::Red, 10.0);

	}
};