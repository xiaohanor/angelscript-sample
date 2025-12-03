class AMedallionHydraSplitProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDamageTriggerComponent DamageTriggerComp;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent 	CameraShakeForceFeedbackComponent;

	UPROPERTY(DefaultComponent)
	USanctuaryBossSplineMovementComponent SplineMovementComp;

	UMedallionPlayerReferencesComponent RefsComp;

	float SidewaysSpeed = 0.0;
	float Gravity = 3000.0;
	float InitialZVelocity = 2500.0;
	float Drag = 200.0;

	float ZVelocity = 0.0;
	float LifeTime = 10.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ZVelocity = InitialZVelocity;
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Mio);
		DamageTriggerComp.OnPlayerDamagedByTrigger.AddUFunction(this, n"HandlePlayerOverlap");
	}

	UFUNCTION()
	private void HandlePlayerOverlap(AHazePlayerCharacter Player)
	{
		if (GameTimeSinceCreation > 0.2)
			Explode();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ZVelocity -= Gravity * DeltaSeconds;

		SidewaysSpeed = Math::FInterpConstantTo(SidewaysSpeed, 0, DeltaSeconds, Drag);

		FVector2D DeltaMove = FVector2D(SidewaysSpeed, ZVelocity);

		FHitResult HitResult = SplineMovementComp.SetSplineLocation(
			SplineMovementComp.GetSplineLocation() + DeltaMove * DeltaSeconds,
			true);

		FVector Direction = SplineMovementComp.ConvertSplineDirectionToWorldDirection(DeltaMove);
		FRotator Rotation = FRotator::MakeFromX(Direction);

		SetActorRotation(Rotation);

		if (HitResult.bBlockingHit)
			Explode();

		if (GameTimeSinceCreation >= LifeTime)
			DestroyActor();
	}

	void Explode()
	{
		FSanctuaryBossMedallionManagerEventProjectileData Data;
		Data.Projectile = this;
		Data.ProjectileType = EMedallionHydraProjectileType::Rain;

		UMedallionHydraAttackManagerEventHandler::Trigger_OnProjectileImpact(RefsComp.Refs.HydraAttackManager, Data);

		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
		BP_Explode();
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Explode(){}
};