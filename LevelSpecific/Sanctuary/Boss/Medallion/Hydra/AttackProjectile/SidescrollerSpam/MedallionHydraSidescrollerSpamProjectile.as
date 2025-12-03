class AMedallionHydraSidescrollerSpamProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TelegraphRoot;
	default TelegraphRoot.SetAbsolute(true, true);

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY()
	FRuntimeFloatCurve ArcCurve;

	UPROPERTY()
	ASanctuaryBossMedallionHydra Hydra;

	const float FlightDuration = 1.5;
	const float MissTargetMultiplier = 4.0;
	const float DamageRadius = 200.0;
	float ArcHeight = 1000.0;

	bool bValidGroundTarget = false;

	FVector StartLocation;
	FVector TargetLocation;

	UMedallionPlayerReferencesComponent RefsComp;

	ASanctuaryBossArenaFloatingPlatform FloatingPlatform;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;

		if (bValidGroundTarget)
		{
			QueueComp.Duration(FlightDuration, this, n"FlyToTargetUpdate");
			QueueComp.Event(this, n"Explode");
			TelegraphRoot.SetWorldLocation(TargetLocation);
		}
		else
		{
			QueueComp.Duration(FlightDuration * MissTargetMultiplier, this, n"FlyBeyondTargetUpdate");
			QueueComp.Event(this, n"Deactivate");
			TelegraphRoot.SetHiddenInGame(true, true);
		}

		ArcHeight *= Math::RandRange(0.8, 1.25);

		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Mio);
	}

	UFUNCTION()
	private void FlyToTargetUpdate(float Alpha)
	{
		FVector Location = Math::Lerp(StartLocation, TargetLocation, Alpha);
		Location.Z += ArcCurve.GetFloatValue(Alpha) * ArcHeight;
		SetActorLocation(Location);
	}

	UFUNCTION()
	private void Explode()
	{
		BP_Explode();

		if (FloatingPlatform != nullptr)
			FauxPhysics::ApplyFauxImpulseToActorAt(FloatingPlatform, ActorLocation, FVector::DownVector * 500.0);

		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
		
		for (auto Player : Game::Players)
		{
			if (Player.GetDistanceTo(this) < DamageRadius)
				Player.DamagePlayerHealth(0.5);
		}

		FSanctuaryBossMedallionManagerEventProjectileData Params;
		Params.Projectile = this;
		Params.ProjectileType = EMedallionHydraProjectileType::Spam;
		Params.MaybeTargetPlayer = Game::GetClosestPlayer(ActorLocation);

		UMedallionHydraAttackManagerEventHandler::Trigger_OnProjectileImpact(RefsComp.Refs.HydraAttackManager, Params);

		DestroyActor();
	}

	UFUNCTION()
	private void FlyBeyondTargetUpdate(float Alpha)
	{
		FVector Location = Math::Lerp(StartLocation, TargetLocation, Alpha * MissTargetMultiplier);
		Location.Z += ArcCurve.GetFloatValue(Alpha * MissTargetMultiplier) * ArcHeight;
		SetActorLocation(Location);
	}

	UFUNCTION()
	private void Deactivate()
	{
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Explode(){}
};