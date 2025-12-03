UCLASS(Abstract)
class AMeltdownBossPhaseThreeLavaMoleProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AMeltdownBossPhaseThreeTelegraph> TelegraphClass;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> MissileImpactShake;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect MissileImpactFeedbackShake;

	UPROPERTY()
	FVector Velocity;
	UPROPERTY()
	float Lifetime = 5.0;
	UPROPERTY()
	float Gravity = 9500;
	UPROPERTY()
	float HorizontalSpeed = 4000.0;

	// Whether to destroy the actor or disable it when it expires
	UPROPERTY()
	bool bDestroyOnExpire = true;

	private bool bLaunched = false;
	private float Timer = 0.0;
	AMeltdownBossPhaseThreeTelegraph Telegraph;
	private FVector OriginalLaunchDirection;

	AMeltdownBossPhaseThreeLavaMole SpawnerLavaMole;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION(DevFunction)
	void Launch(FVector TargetLocation, FVector LaunchVelocity)
	{
		bLaunched = true;
		Velocity = LaunchVelocity;
		Timer = 0.0;

		Telegraph = MeltdownBossPhaseThree::SpawnTelegraph(TelegraphClass, TargetLocation, 150.0, Type = ETelegraphDecalType::Scifi);

		OriginalLaunchDirection = Velocity.GetSafeNormal();
		ActorRotation = FRotator::MakeFromX(OriginalLaunchDirection);

		SetActorTickEnabled(true);

		UMeltdownBossPhaseThreeLavaMoleProjectileEffectHandler::Trigger_Spawn(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bLaunched)
			return;

		Velocity.Z -= Gravity * DeltaSeconds;
		FVector TargetLocation = ActorLocation + Velocity * DeltaSeconds;

		ActorRotation = FRotator::MakeFromX(Velocity);

		FHazeTraceSettings Trace;
		Trace.UseLine();
		Trace.TraceWithChannel(ECollisionChannel::WeaponTraceEnemy);
		Trace.IgnorePlayers();

		FHitResult Hit = Trace.QueryTraceSingle(ActorLocation, TargetLocation);
		if (Hit.bBlockingHit)
		{
			FMeltdownBossPhaseThreeLavaMoleProjectileImpactParams ImpactParams;
			ImpactParams.ImpactLocation = Hit.ImpactPoint;
			UMeltdownBossPhaseThreeLavaMoleProjectileEffectHandler::Trigger_Impact(this, ImpactParams);

			for (AHazePlayerCharacter Player : Game::Players)
			{
				if (Hit.ImpactPoint.Dist2D(Player.ActorLocation) < 900)
				{
					Player.PlayCameraShake(MissileImpactShake,this);
			 		Player.PlayForceFeedback(MissileImpactFeedbackShake,false,false,this);
				}
			}

			Movement::KnockbackPlayersInRadius(Hit.ImpactPoint, 150.0, 600, 1000);
			PlayerHealth::DamagePlayersInRadius(Hit.ImpactPoint, 150.0, 0.5);

			FMeltdownBossPhaseThreeLavaMoleImpactParams Params;
			Params.ImpactLocation = ActorLocation;
			UMeltdownBossPhaseThreeLavaMoleEffectHandler::Trigger_Impact(SpawnerLavaMole, Params);

			Destroy();
			return;
		}

		ActorLocation = TargetLocation;
		
		Timer += DeltaSeconds;
		if (Timer > Lifetime)
		{
			Destroy();
		}
	}

	void Destroy()
	{
		Telegraph.HideAndDestroy();
		Telegraph = nullptr;

		if (bDestroyOnExpire)
			DestroyActor();
		else
			AddActorDisable(this);
	}
};

struct FMeltdownBossPhaseThreeLavaMoleProjectileImpactParams
{
	UPROPERTY()
	FVector ImpactLocation;
}

UCLASS(Abstract)
class UMeltdownBossPhaseThreeLavaMoleProjectileEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Spawn() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Impact(FMeltdownBossPhaseThreeLavaMoleProjectileImpactParams ImpactParams) {}
}