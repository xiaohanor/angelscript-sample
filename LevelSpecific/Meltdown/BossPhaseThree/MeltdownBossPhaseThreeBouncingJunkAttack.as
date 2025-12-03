class AMeltdownBossPhaseThreeBouncingJunkAttack : AHazeActor
{
UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;

	UPROPERTY(DefaultComponent)
	UArrowComponent Arrow;
	default Arrow.RelativeScale3D = FVector(10);
#endif

	UPROPERTY(DefaultComponent)
	UDecalComponent BlobShadow;

	UPROPERTY(EditAnywhere)
	float HorizontalSpeed = 1500.0;
	UPROPERTY(EditAnywhere)
	float Radius = 150.0;
	UPROPERTY(EditAnywhere)
	float Gravity = 3000.0;
	UPROPERTY(EditAnywhere)
	float Lifetime = 30.0;
	UPROPERTY(EditAnywhere)
	FVector AdditionalLaunchVelocity = FVector(0, 0, 0);

	UPROPERTY(EditAnywhere)
	UNiagaraSystem Spawneffect;
	UPROPERTY(EditAnywhere)
	UNiagaraSystem BreakEffect;
	UPROPERTY(EditAnywhere)
	int MaxBounceCountIncludingSplits = 5;

	private FVector Velocity;
	private float LaunchTimer = 0.0;
	private bool bLaunched = false;
	private FTransform OriginalActorTransform;
	private int BounceCount = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OriginalActorTransform = ActorTransform;
		AddActorDisable(this);
		BlobShadow.SetAbsolute(true, true, true);
	}

	UFUNCTION(DevFunction)
	void Launch()
	{
		bLaunched = true;
		LaunchTimer = 0.0;
		Velocity = ActorForwardVector.ConstrainToPlane(FVector::UpVector).GetSafeNormal() * HorizontalSpeed + AdditionalLaunchVelocity;
		Niagara::SpawnOneShotNiagaraSystemAtLocation(Spawneffect, ActorLocation,ActorRotation,ActorScale3D * 2);
		RemoveActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bLaunched)
		{
			LaunchTimer += DeltaSeconds;
			if (LaunchTimer >= 10.0)
			{
				Explode();
				return;
			}

			FVector DeltaMove = Velocity * DeltaSeconds;
			DeltaMove += FVector::DownVector * 0.5 * DeltaSeconds * DeltaSeconds * Gravity;
			Velocity += FVector::DownVector * DeltaSeconds * Gravity;

			FVector NewLocation = ActorLocation + DeltaMove;
			if (!NewLocation.Equals(ActorLocation))
			{
				FHazeTraceSettings Trace;
				Trace.UseSphereShape(Radius);
				Trace.TraceWithChannel(ECollisionChannel::WeaponTraceEnemy);
				Trace.IgnoreActor(this);
				Trace.IgnorePlayers();

				FHitResult Hit = Trace.QueryTraceSingle(ActorLocation, NewLocation);
				if (Hit.bBlockingHit && !Hit.bStartPenetrating)
				{
					ActorLocation = Hit.Location;
					Niagara::SpawnOneShotNiagaraSystemAtLocation(BreakEffect, ActorLocation);	
					SpawnShockwave();
					
						Velocity = Math::GetReflectionVector(Velocity, Hit.ImpactNormal);

						BounceCount += 1;
						if (BounceCount > MaxBounceCountIncludingSplits)
							DestroyActor();
					
				}
				else
				{
					SetActorLocationAndRotation(
						NewLocation,
						FRotator::MakeFromX(DeltaMove)
					);
				}
			}

			for (AHazePlayerCharacter Player : Game::Players)
			{
				if (Player.ActorCenterLocation.Distance(ActorLocation) < Radius + Player.CapsuleComponent.ScaledCapsuleRadius)
					Player.KillPlayer();
			}

			UpdateBlobShadow();
		}
	}

	UFUNCTION(BlueprintEvent)
	void SpawnShockwave()
	{

	}

	void UpdateBlobShadow()
	{
		FHazeTraceSettings Trace;
		Trace.UseLine();
		Trace.TraceWithChannel(ECollisionChannel::WeaponTraceEnemy);
		Trace.IgnoreActor(this);
		Trace.IgnorePlayers();

		FHitResult Hit = Trace.QueryTraceSingle(ActorLocation, ActorLocation - FVector(0, 0, 5000));
		if (Hit.bBlockingHit)
		{
			BlobShadow.WorldLocation = Hit.Location;
			BlobShadow.SetHiddenInGame(false);
		}
		else
		{
			BlobShadow.SetHiddenInGame(true);
		}
	}

	void Explode()
	{
		AddActorDisable(this);
		bLaunched = false;
		ActorTransform = OriginalActorTransform;
	}
};