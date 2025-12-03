class AMedallionHydraRainProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDamageTriggerComponent DamageTriggerComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;
	
	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent 	CameraShakeForceFeedbackComponent;

	UPROPERTY(DefaultComponent)
	USanctuaryBossSplineMovementComponent SplineMovementComp;

	UPROPERTY()
	ASanctuaryBossMedallionHydra Hydra;

	UMedallionPlayerMergeHighfiveJumpComponent HighfiveComp;

	AHazePlayerCharacter TargetPlayer;

	//Settings
	const float ArcHeight = 2000.0;
	const float FlightDuration = 2.0;
	const float FallSpeed = 1500.0;
	const float Damage = 0.5;
	const FVector2D FallVector = FVector2D(0.0, -FallSpeed);
	const float KillHeight = -2000.0;
	const float TargetHeight = 1800.0;

	float WaitDuration = 0.0;
	FVector StartLocation;
	float TargetSplineOffset;

	bool bFalling = false;

	bool bSineRain = false;

	float SplineOffset;

	UMedallionPlayerReferencesComponent RefsComp;	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;
		// CollisionComp.OnComponentBeginOverlap.AddUFunction(this, n"HandleOverlap");
		QueueComp.Duration(FlightDuration, this, n"FlightUpdate");
		QueueComp.Idle(WaitDuration);
		QueueComp.Event(this, n"Arrived");
		HighfiveComp = UMedallionPlayerMergeHighfiveJumpComponent::GetOrCreate(Game::Mio);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Mio);

		DamageTriggerComp.OnPlayerDamagedByTrigger.AddUFunction(this, n"HandlePlayerOverlap");
	}

	private FVector GetTargetWorldLocation()
	{
		float PlayerSplineProgress = SplineMovementComp.ConvertWorldLocationToSplineLocation(TargetPlayer.ActorLocation).X;
		float TargetSplineProgress = PlayerSplineProgress + TargetSplineOffset;

		return SplineMovementComp.ConvertSplineLocationToWorldLocation(FVector2D(TargetSplineProgress, TargetHeight));
	}

	UFUNCTION()
	private void FlightUpdate(float Alpha)
	{
		FVector Location = Math::Lerp(StartLocation, GetTargetWorldLocation(), Alpha);
		Location.Z += Math::Sin(Alpha * PI) * ArcHeight;

		FVector Direction = (Location - ActorLocation).GetSafeNormal(); 

		if (!Direction.IsNearlyZero())
			SetActorRotation(Direction.Rotation());

		SetActorLocation(Location);
	}

	UFUNCTION()
	private void Arrived()
	{
		bFalling = true;

		FVector2D TargetSplineLocation = SplineMovementComp.ConvertWorldLocationToSplineLocation(GetTargetWorldLocation());
		SplineMovementComp.SetSplineLocation(TargetSplineLocation);
		SetActorRotation(FVector::DownVector.Rotation());
	}

	UFUNCTION()
	private void HandlePlayerOverlap(AHazePlayerCharacter Player)
	{
		Explode();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bFalling)
		{
			FHitResult HitResult = SplineMovementComp.SetSplineLocation(
				SplineMovementComp.GetSplineLocation() + FallVector * DeltaSeconds,
				true);

			if (HitResult.bBlockingHit)
			{
				auto FloatingPlatform = Cast<ASanctuaryBossArenaFloatingPlatform>(HitResult.Actor);
				
				if (FloatingPlatform != nullptr)
					FauxPhysics::ApplyFauxImpulseToActorAt(FloatingPlatform, ActorLocation, FVector::DownVector * 500.0);

				Explode();
			}

			if (SplineMovementComp.GetSplineLocation().Y < KillHeight)
				DestroyActor();

			if (HighfiveComp.IsHighfiveJumping())
				DestroyActor();
		}
	}

	void Explode()
	{
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();

		FSanctuaryBossMedallionManagerEventProjectileData Data;
		Data.Projectile = this;
		Data.ProjectileType = EMedallionHydraProjectileType::Rain;

		UMedallionHydraAttackManagerEventHandler::Trigger_OnProjectileImpact(RefsComp.Refs.HydraAttackManager, Data);

		BP_Explode();
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Explode(){}
};