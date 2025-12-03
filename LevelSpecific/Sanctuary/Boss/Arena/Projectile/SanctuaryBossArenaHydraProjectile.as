class ASanctuaryBossArenaHydraProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSphereComponent HazeSphereComp;
	default HazeSphereComp.SetAbsolute(true, true);

	UPROPERTY(DefaultComponent, Attach = HazeSphereComp)
	UGodrayComponent GodrayComp;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY()
	ASanctuaryBossMedallionHydra Hydra;

	UMedallionPlayerReferencesComponent RefsComp;

	float ArcHeight = 2000.0;
	float FlightTime = 0.0;
	float FlightDuration = 2.0;
	float GrowingScale = 1.0;
	float DamageRadius = 200.0;
	FVector StartLocation;
	FVector TargetOffset = FVector::ZeroVector;

	float HazeSphereMaxOpacity = 0.0;
	float HazeSphereOpacityFadeSpeed = 0.1;
	float HazeSphereOpacity = 0.0;

	bool bDisabling = false;

	ASanctuaryBossArenaHydraTarget TargetActor;
	FVector TargetLocation = FVector::ZeroVector;

	ASanctuaryBossArenaFloatingPlatform FloatingPlatform;

	UMedallionPlayerMergeHighfiveJumpComponent HighfiveComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;

		if (TargetActor != nullptr)
			TargetActor.bProjectileTargeted = true;
		HighfiveComp = UMedallionPlayerMergeHighfiveJumpComponent::GetOrCreate(Game::Mio);

		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (TargetActor != nullptr)
			TargetLocation = TargetActor.ActorTransform.TransformPositionNoScale(TargetOffset);
			
		else if (TargetLocation == FVector::ZeroVector)
			return;

		HazeSphereOpacity += HazeSphereOpacityFadeSpeed * DeltaSeconds;
		HazeSphereOpacity = Math::Min(HazeSphereOpacity, HazeSphereMaxOpacity);

		float HazeSphereOpacityMultiplier = Math::Lerp(0.8, 1.0, (Math::Sin(GameTimeSinceCreation * 5.0) + 1.5));

		HazeSphereOpacity *= HazeSphereOpacityMultiplier;

		HazeSphereComp.SetOpacityValue(HazeSphereOpacity);

		HazeSphereComp.SetWorldLocation(TargetLocation);

		GodrayComp.SetWorldLocation(TargetLocation);
		
		FlightTime += DeltaSeconds;
		float Alpha = Math::Min(1.0, FlightTime / FlightDuration);

		FVector Location = Math::Lerp(StartLocation, TargetLocation, Alpha);
		Location.Z += Math::Sin(Alpha * PI) * ArcHeight;

		FVector Direction = (Location - ActorLocation).GetSafeNormal(); 

		ActorLocation = Location;
		ActorScale3D = FVector::OneVector; 

		if (Alpha >= 1.0)
			Explode(Direction);

		if (HighfiveComp.IsHighfiveJumping() && !bDisabling)
			SmoothDisable();
	}

	void Explode(FVector ProjectileDirection)
	{
		if (TargetActor != nullptr)
			TargetActor.bProjectileTargeted = false;

		for (auto Player : Game::Players)
		{
			if (Player.GetDistanceTo(this) < DamageRadius)
				Player.DamagePlayerHealth(0.5);
		}

		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
		BP_Explode();

		FSanctuaryBossMedallionManagerEventProjectileData Data;
		Data.Projectile = this;
		Data.ProjectileType = EMedallionHydraProjectileType::Basic;

		UMedallionHydraAttackManagerEventHandler::Trigger_OnProjectileImpact(RefsComp.Refs.HydraAttackManager, Data);

		if (FloatingPlatform != nullptr)
		{
			FauxPhysics::ApplyFauxImpulseToActorAt(FloatingPlatform, ActorLocation, ProjectileDirection * 2000.0);
		}

		DestroyActor();
	}

	void SmoothDisable()
	{
		bDisabling = true;
		BP_SmoothDisable();
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Explode(){}

	UFUNCTION(BlueprintEvent)
	void BP_SmoothDisable(){}
};