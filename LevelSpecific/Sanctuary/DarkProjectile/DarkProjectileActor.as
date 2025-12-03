class ADarkProjectileActor : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.bGenerateOverlapEvents = false;
	default Mesh.AddTag(ComponentTags::HideOnCameraOverlap);
	default Mesh.bCanEverAffectNavigation = false;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UDarkProjectileMovementComponent MovementComp;
	default MovementComp.bUseGravity = false;
	default MovementComp.bConstrainVelocity = true;
	default MovementComp.MaxVelocity = 6000.0;
	default MovementComp.TraceTypeQuery = ETraceTypeQuery::WeaponTraceZoe;

	UProjectileProximityManagerComponent ProximityManager;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FHitResult HitResult;
		if (MovementComp.PerformMove(DeltaTime, 20.0, HitResult))
		{
			FDarkProjectileHitData HitData;
			HitData.Location = HitResult.ImpactPoint;
			HitData.Normal = HitResult.Normal;
			HitData.Velocity = MovementComp.Velocity;

			if (HitResult.Actor != nullptr)
			{
				auto ResponseComp = UDarkProjectileResponseComponent::Get(HitResult.Actor);

				if (ResponseComp != nullptr)
					ResponseComp.OnHit.Broadcast(HitData);

				//Deal damage to target
				UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(HitResult.Actor);
				if (HealthComp != nullptr)
					HealthComp.TakeDamage(0.4, EDamageType::Darkness, Game::Zoe);
			}

			UDarkProjectileEventHandler::Trigger_Hit(this, HitData);
			Deactivate();
			DestroyActor();
		}
	}

	UFUNCTION()
	void Activate()
	{
		SetActorHiddenInGame(false);
		
		UDarkProjectileEventHandler::Trigger_Activated(this);
	}
	
	UFUNCTION()
	void Deactivate()
	{
		UDarkProjectileEventHandler::Trigger_Deactivated(this);

		SetActorHiddenInGame(true);
		SetActorTickEnabled(false);

		if (ProximityManager != nullptr)
			ProximityManager.UnregisterProjectile(this);
	}

	UFUNCTION()
	void Launch(const FVector& Velocity,
		const FDarkProjectileTargetData& HomingTarget,
		UProjectileProximityManagerComponent ProjectileProximityManager = nullptr)
	{
		MovementComp.Initialize(Velocity, HomingTarget);

		SetActorTickEnabled(true);
		UDarkProjectileEventHandler::Trigger_Launch(this, FDarkProjectileLaunchData(Velocity));

		ProximityManager = ProjectileProximityManager;
		if (ProximityManager != nullptr)
			ProximityManager.RegisterProjectile(this);
	}
}