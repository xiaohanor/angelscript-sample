UCLASS(Abstract)
class AMeltdownBossPhaseTwoBounceAttack : AHazeActor
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
	float DownwardOffsetWhenSplitting = 150.0;
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
	int MaxSplitCount = 2;
	UPROPERTY(EditAnywhere)
	int MaxBounceCountIncludingSplits = 5;
	UPROPERTY(EditAnywhere)
	float SplitScaleFactor = 0.5;
	UPROPERTY(EditAnywhere)
	float SplitFirstAnglePct = 0.5;
	UPROPERTY(EditAnywhere)
	float SplitSecondAnglePct = 1.0;

	private FVector Velocity;
	private float LaunchTimer = 0.0;
	private bool bLaunched = false;
	private FTransform OriginalActorTransform;
	private int BounceCount = 0;
	private int SplitCount = 0;

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

					if (SplitCount < MaxSplitCount)
					{
						for (int i = 0; i < 2; ++i)
						{
							auto Split = Cast<AMeltdownBossPhaseTwoBounceAttack>(SpawnActor(
								Class,
								ActorLocation + FVector(0, 0, -DownwardOffsetWhenSplitting * SplitScaleFactor),
								ActorRotation));

							Split.Launch();

							FRotator FromRotation = FRotator::MakeFromX(-Velocity);
							FRotator ToRotation = FRotator::MakeFromX(Math::GetReflectionVector(Velocity, Hit.ImpactNormal));
							float AngleAlpha = i == 0 ? SplitFirstAnglePct : SplitSecondAnglePct;

							FRotator WantedRotation = Math::LerpShortestPath(FromRotation, ToRotation, AngleAlpha);
							Split.SetActorScale3D(ActorScale3D * SplitScaleFactor);
							Split.Velocity = WantedRotation.ForwardVector * Velocity.Size();
							Split.Radius = Radius * SplitScaleFactor;
							Split.HorizontalSpeed = HorizontalSpeed;
							Split.MaxBounceCountIncludingSplits = MaxBounceCountIncludingSplits;
							Split.Gravity = Gravity;
							Split.Lifetime = Lifetime;
							Split.BounceCount = BounceCount+1;
							Split.MaxSplitCount = MaxSplitCount;
							Split.SplitCount = SplitCount+1;
							Split.SplitScaleFactor = SplitScaleFactor;
							Split.SplitFirstAnglePct = SplitFirstAnglePct;
							Split.SplitSecondAnglePct = SplitSecondAnglePct;
						}

						if (SplitCount == 0)
						{
							AddActorDisable(this);
							bLaunched = false;
							ActorTransform = OriginalActorTransform;
						}
						else
						{
							DestroyActor();
						}
					}
					else
					{
						Velocity = Math::GetReflectionVector(Velocity, Hit.ImpactNormal);

						BounceCount += 1;
						if (BounceCount > MaxBounceCountIncludingSplits)
							DestroyActor();
					}
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