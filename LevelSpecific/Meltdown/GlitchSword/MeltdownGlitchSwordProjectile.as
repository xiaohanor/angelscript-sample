class AMeltdownGlitchSwordProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	float InitialSpeed = 1000;
	UPROPERTY()
	float Acceleration = 60000;
	UPROPERTY()
	float MaxSpeed = 30000;
	UPROPERTY()
	float Damage = 3;

	AHazePlayerCharacter OwningPlayer;
	UHazeActorLocalSpawnPoolComponent ProjectilePool;

	const float MaxAliveTime = 4.0;
	float TimeOfFired = -1.0;
	float Speed = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UMeltdownGlitchShootingProjectileEffectHandler::Trigger_OnProjectileSpawned(this);
	}

	void Fire()
	{
		UMeltdownGlitchShootingProjectileEffectHandler::Trigger_OnProjectileFired(this);
		RemoveActorDisable(this);
		TimeOfFired = Time::GetGameTimeSeconds();
		Speed = InitialSpeed;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float AliveTime = Time::GetGameTimeSince(TimeOfFired);
		if(AliveTime > MaxAliveTime)
		{
			UMeltdownGlitchShootingProjectileEffectHandler::Trigger_OnProjectileExpired(this);
			Kill();
			return;
		}

		FVector Delta;
		Delta += ActorForwardVector * (Speed * DeltaSeconds);
		Speed += Acceleration * DeltaSeconds;
		Speed = Math::Clamp(Speed, 0.0, MaxSpeed);

		if(Delta.IsNearlyZero())
			return;

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTracePlayer);
		Trace.UseLine();
		Trace.SetReturnPhysMaterial(true);

		FHitResult Hit = Trace.QueryTraceSingle(ActorLocation, ActorLocation + Delta);
		if (Hit.bBlockingHit)
		{
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

			Kill();
			return;
		}

		if (!Delta.IsNearlyZero())
		{
			FTransform Transform = GetActorTransform();
			Transform.SetLocation(Transform.GetLocation() + Delta);
			Transform.SetRotation(Transform.GetRotation() * FQuat(FVector::ForwardVector, DeltaSeconds));

			// float ScaleAlpha = Math::Lerp(1.0, 1.25, Math::Saturate(AliveTime / 0.5));
			// Transform.SetScale3D(Transform.GetScale3D() * FVector(1, ScaleAlpha, 1));

			SetActorTransform(Transform);
		}
	}

	void Kill()
	{
		AddActorDisable(this);
		TimeOfFired = -1.0;
		ProjectilePool.UnSpawn(this);
	}
};