class ASanctuaryBossFinalPhaseBlackSmoke : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueue;

	UPROPERTY()
	UNiagaraSystem ExplosionVFX;

	UPROPERTY()
	float Velocity = 10000.0;

	ASanctuaryBossFinalPhaseMioGlowActor MioGlowActor;
	ASanctuaryLightBirdShield LightShield;

	FVector InitialForward;
	float HomingMultiplier;

	ASanctuaryBossHeartBeatManager HeartManager;

	UPROPERTY(BlueprintReadOnly)
	bool bHitTarget = false;

	float Damage = 0.5;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActionQueue.Duration(3.0, this, n"UpdateHoming");
		InitialForward = ActorForwardVector;

		TListedActors<ASanctuaryLightBirdShield> ListedLightShields;
		LightShield = ListedLightShields.Single;
	}

	UFUNCTION()
	private void UpdateHoming(float Alpha)
	{
		HomingMultiplier = Alpha;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bHitTarget)
			return;
		
		if (LightShield == nullptr)
			return;

		FVector HomingMovement = (Game::Zoe.ActorCenterLocation - ActorLocation).GetSafeNormal();
		FVector Direction = Math::Lerp(InitialForward, HomingMovement, HomingMultiplier);
		FVector DeltaMove = Direction * Velocity * DeltaSeconds;

		if (DeltaMove.Size() + LightShield.CurrentRadius > ActorLocation.Distance(LightShield.ActorLocation))
		{
			FVector HitLocation = LightShield.ActorLocation + -Direction * LightShield.CurrentRadius;
			HitTarget(HitLocation);
			SetActorLocation(HitLocation);
			DestroyActor();
		}
		else if (DeltaMove.Size() > ActorLocation.Distance(Game::Zoe.ActorCenterLocation))
		{
			HeartManager.OnSmokeHeartAttackZoe.Broadcast();
			Game::Zoe.DamagePlayerHealth(Damage);
			SetActorLocation(Game::Zoe.ActorCenterLocation);
			BP_HitTarget();
			DestroyActor();
		}
		else
		{
			AddActorWorldOffset(DeltaMove);
		}

		SetActorRotation(Direction.Rotation());
	}

	private void HitTarget(FVector HitLocation)
	{
		bHitTarget = true;
		LightShield.LightShieldHit(HitLocation);
		BP_HitTarget();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_HitTarget(){}

	UFUNCTION()
	private void HandleDeactivated()
	{
		DestroyActor();
	}
};