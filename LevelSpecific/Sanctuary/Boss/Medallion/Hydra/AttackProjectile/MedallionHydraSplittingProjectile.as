class AMedallionHydraSplittingProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ProjectileRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TelegraphRoot;
	default TelegraphRoot.SetAbsolute(true, true);

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent 	CameraShakeForceFeedbackComponent;

	UPROPERTY()
	TSubclassOf<AMedallionHydraSplitProjectile> SplitProjectileClass;

	UPROPERTY()
	ASanctuaryBossMedallionHydra Hydra;

	UMedallionPlayerMergeHighfiveJumpComponent HighfiveComp;

	UMedallionPlayerReferencesComponent RefsComp;

	float ArcHeight = 3000.0;
	float FlightDuration = 2.0;
	float DamageRadius = 200.0;

	UPROPERTY()
	int ProjectilesToSpawn = 2;

	UPROPERTY()
	float ProjectileSpeedSpread = 800.0;

	FVector StartLocation;
	FVector TargetOffset = FVector::ZeroVector;

	ASanctuaryBossArenaHydraTarget TargetActor;
	FVector TargetLocation = FVector::ZeroVector;

	ASanctuaryBossArenaFloatingPlatform FloatingPlatform;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;

		if (TargetActor != nullptr)
			TargetActor.bProjectileTargeted = true;

		QueueComp.Duration(FlightDuration, this, n"FlightUpdate");
		QueueComp.Event(this, n"Explode");
		HighfiveComp = UMedallionPlayerMergeHighfiveJumpComponent::GetOrCreate(Game::Mio);

		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Mio);
	}

	UFUNCTION()
	private void FlightUpdate(float Alpha)
	{
		FVector Location = Math::Lerp(StartLocation, TargetLocation, Alpha);
		Location.Z += Math::Sin(Alpha * PI) * ArcHeight;

		FVector Direction = (Location - ActorLocation).GetSafeNormal(); 

		if (!Direction.IsNearlyZero())
			SetActorRotation(Direction.Rotation());

		SetActorLocation(Location);

		TelegraphRoot.SetWorldLocation(TargetLocation);

		ProjectileRoot.SetRelativeRotation(FRotator(0.0, 0.0, Math::Lerp(0.0, 1200.0, Alpha)));

		if (HighfiveComp.IsHighfiveJumping())
			DestroyActor();
	}

	UFUNCTION()
	void Explode()
	{
		if (TargetActor != nullptr)
			TargetActor.bProjectileTargeted = false;

		for (auto Player : Game::Players)
		{
			if (Player.GetDistanceTo(this) < DamageRadius)
				Player.DamagePlayerHealth(0.5);
		}

		BP_Explode();
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();

		for (int i = 0; i < ProjectilesToSpawn; i++)
		{
			const float Alpha = float(i) / (ProjectilesToSpawn - 1);
			const float Factor = Math::Lerp(-0.5, 0.5, Alpha);
			const float SidewaysSpeed = (ProjectileSpeedSpread * ProjectilesToSpawn) * Factor;
			const float InitialZVelocity = (ProjectilesToSpawn * 0.5 - Math::Abs(Factor)) * 1000.0 + 900.0;

			PrintToScreen("InitialZ" + Math::Abs(Factor), 2.0);

			auto SplitProjectile = SpawnActor(SplitProjectileClass, ActorLocation, ActorRotation, bDeferredSpawn = true);
			SplitProjectile.SidewaysSpeed = SidewaysSpeed;
			//SplitProjectile.InitialZVelocity = InitialZVelocity;
			FinishSpawningActor(SplitProjectile);

			FSanctuaryBossMedallionManagerEventSplitProjectileData Params;
			Params.Projectile = SplitProjectile;
			Params.SplitCount = ProjectilesToSpawn;

			UMedallionHydraAttackManagerEventHandler::Trigger_OnSplitProjectileSplit(RefsComp.Refs.HydraAttackManager, Params);
		}

		FSanctuaryBossMedallionManagerEventProjectileData Params;
		Params.Projectile = this;
		Params.ProjectileType = EMedallionHydraProjectileType::Splitting;
		Params.MaybeTargetPlayer = Game::GetClosestPlayer(ActorLocation);

		UMedallionHydraAttackManagerEventHandler::Trigger_OnProjectileImpact(RefsComp.Refs.HydraAttackManager, Params);

		if (FloatingPlatform != nullptr)
		{
			FauxPhysics::ApplyFauxImpulseToActorAt(FloatingPlatform, ActorLocation, ActorForwardVector * 2000.0);
		}

		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Explode(){}
};