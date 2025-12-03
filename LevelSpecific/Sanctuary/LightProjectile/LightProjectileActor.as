class ALightProjectileActor : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	USphereComponent Collision;
	default Collision.SphereRadius = 20.0;
	default Collision.bGenerateOverlapEvents = false;
	default Collision.CollisionProfileName = n"NoCollision";

	// TODO: Temporarily using dark stuff
	UPROPERTY(DefaultComponent, ShowOnActor)
	UDarkProjectileMovementComponent MovementComp;
	default MovementComp.TraceTypeQuery = ETraceTypeQuery::WeaponTraceMio;

	UProjectileProximityManagerComponent ProximityManager;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FHitResult HitResult;
		if (MovementComp.PerformMove(DeltaTime, Collision.SphereRadius, HitResult))
		{
			FLightProjectileHitData HitData;
			HitData.Location = HitResult.ImpactPoint;
			HitData.Normal = HitResult.Normal;
			HitData.Velocity = MovementComp.Velocity;

			if (HitResult.Actor != nullptr)
			{
				auto ResponseComp = ULightProjectileResponseComponent::Get(HitResult.Actor);
				if (ResponseComp != nullptr)
					ResponseComp.OnHit.Broadcast(HitData);

				// Deal damage to target
				auto HealthComp = UBasicAIHealthComponent::Get(HitResult.Actor);
				if (HealthComp != nullptr)
					HealthComp.TakeDamage(0.1, EDamageType::Light, Game::Mio);
			}

			ULightProjectileEventHandler::Trigger_Hit(this, HitData);
			Deactivate();
			DestroyActor();
		}
	}

	UFUNCTION()
	void Activate()
	{
		ULightProjectileEventHandler::Trigger_Activated(this);
	}
	
	UFUNCTION()
	void Deactivate()
	{
		ULightProjectileEventHandler::Trigger_Deactivated(this);

		SetActorTickEnabled(false);

		if (ProximityManager != nullptr)
			ProximityManager.UnregisterProjectile(this);
	}

	UFUNCTION()
	void Launch(const FVector& Velocity,
		const FLightProjectileTargetData& HomingTarget,
		UProjectileProximityManagerComponent ProjectileProximityManager = nullptr)
	{
		// TODO: Temporarily using dark stuff
		FDarkProjectileTargetData TempData(
			HomingTarget.Component,
			HomingTarget.WorldLocation,
			HomingTarget.SocketName
		);
		MovementComp.Initialize(Velocity, TempData);

		SetActorTickEnabled(true);
		ULightProjectileEventHandler::Trigger_Launch(this, FLightProjectileLaunchData(Velocity));

		ProximityManager = ProjectileProximityManager;
		if (ProximityManager != nullptr)
			ProximityManager.RegisterProjectile(this);
	}
}