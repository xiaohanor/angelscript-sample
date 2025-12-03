UCLASS(Abstract)
class AMeltdownGlitchBazookaProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UNiagaraComponent EffectTrail;

	UPROPERTY()
	float InitialSpeed = 1000;
	UPROPERTY()
	float Acceleration = 60000;
	UPROPERTY()
	float MaxSpeed = 30000;
	UPROPERTY()
	float Damage = 5;

	AHazePlayerCharacter OwningPlayer;
	UHazeActorLocalSpawnPoolComponent SpawnPool;

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
		TimeOfFired = Time::GetGameTimeSeconds();
		Speed = InitialSpeed;

		UMeltdownGlitchShootingProjectileEffectHandler::Trigger_OnProjectileFired(this);

		Mesh.SetHiddenInGame(false);
		SetActorTickEnabled(true);
		EffectTrail.Activate();
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

			bool bHitRader = Hit.Actor.IsA(AMeltdownBoss);
			FVector ImpactPoint = Hit.ImpactPoint;
			if (bHitRader)
				ImpactPoint += Hit.ImpactNormal * 400;

			FMeltdownGlitchImpact Impact;
			Impact.FiringPlayer = OwningPlayer;
			Impact.ImpactPoint = ImpactPoint;
			Impact.ImpactNormal = Hit.ImpactNormal;
			Impact.Damage = Damage;
			Impact.ProjectileDirection = ActorForwardVector;

			for (auto ResponseComp : ResponseComps)
				ResponseComp.TriggerGlitchHit(Impact);

			FMeltdownGlitchProjectileImpactEffectParams HitEffectParams;
			HitEffectParams.ResponseComponents = ResponseComps;
			HitEffectParams.ImpactPoint = ImpactPoint;
			HitEffectParams.ImpactNormal = Hit.ImpactNormal;
			HitEffectParams.PhysMat = Hit.PhysMaterial;
			HitEffectParams.ProjectileLocation = ActorLocation;
			HitEffectParams.bHitRader = bHitRader;
			UMeltdownGlitchShootingProjectileEffectHandler::Trigger_OnProjectileHit(this, HitEffectParams);

			Kill();
			return;
		}

		if (!Delta.IsNearlyZero())
		{
			FTransform Transform = GetActorTransform();
			Transform.SetLocation(Transform.GetLocation() + Delta);
			Transform.SetRotation(Transform.GetRotation() * FQuat(FVector::ForwardVector, DeltaSeconds));

			float ScaleAlpha = Math::Lerp(1.0, 3.0, Math::Saturate(AliveTime / 1.0));
			Transform.SetScale3D(FVector(ScaleAlpha));

			SetActorTransform(Transform);
		}
	}

	void Kill()
	{
		TimeOfFired = -1.0;
		SetActorTickEnabled(false);
		Mesh.SetHiddenInGame(true);
		EffectTrail.Deactivate();
		Timer::SetTimer(this, n"DestroyProjectile", 1.0);
	}

	UFUNCTION()
	private void DestroyProjectile()
	{
		SpawnPool.UnSpawn(this);
	}
};