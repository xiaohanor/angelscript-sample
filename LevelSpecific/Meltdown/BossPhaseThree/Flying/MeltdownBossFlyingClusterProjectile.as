class AMeltdownBossFlyingClusterProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent ProjectileMesh;

	UPROPERTY(DefaultComponent, Attach = ProjectileMesh)
	UHazeSphereCollisionComponent Collision;

	UPROPERTY()
	ASplineActor SplineActor;

	UHazeSplineComponent SplineComp;

	float CurrentSplineDistance;

	float StartSplinePos;

	int TargetRandomizer;

	AHazePlayerCharacter TargetChar;

	UPROPERTY()
	float Speed = 1700.0;
	UPROPERTY()
	float TurnRate = 50.0;
	UPROPERTY()
	float Lifetime = 10.0;

	UPROPERTY()
	float ExplosionDelay;

	// Whether to destroy the actor or disable it when it expires
	UPROPERTY()
	bool bDestroyOnExpire = true;

	private AHazePlayerCharacter TargetPlayer;
	private bool bLaunched = false;
	private float Timer = 0.0;
	private FVector OriginalLaunchDirection;

	FHazeTimeLike StartSpline; 
	default StartSpline.Duration = 1.0;
	default StartSpline.UseSmoothCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Collision.OnComponentBeginOverlap.AddUFunction(this,n"OnCollisionOverlap");
		AddActorDisable(this);

		StartSpline.BindFinished(this, n"OnSplineDone");
		StartSpline.BindUpdate(this, n"OnSplineUpdating");

		SetActorTickEnabled(false);

		TargetRandomizer = Math::RandRange(0,10);

		if(TargetRandomizer <= 5)
			TargetChar = Game::Mio;
		else
			TargetChar = Game::Zoe;

	}

	UFUNCTION(BlueprintCallable)
	void StartSpawning()
	{
		RemoveActorDisable(this);
		SplineComp = SplineActor.Spline;
		StartSpline.PlayFromStart();
	}

	UFUNCTION()
	private void OnSplineUpdating(float CurrentValue)
	{
		CurrentSplineDistance = SplineComp.GetClosestSplineDistanceToWorldLocation(ActorLocation);
		ActorLocation = SplineComp.GetWorldLocationAtSplineDistance(Math::Lerp(StartSplinePos,SplineComp.SplineLength, CurrentValue));
		SetActorRotation(SplineComp.GetWorldRotationAtSplineDistance(CurrentSplineDistance));
	}

	UFUNCTION()
	private void OnSplineDone()
	{
		Launch(TargetChar);
	}

	UFUNCTION()
	private void OnCollisionOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                                const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player == nullptr)
			return;
		
		Player.DamagePlayerHealth(0.2);
	}

	UFUNCTION(BlueprintEvent)
	void Impact()
	{
	}


	UFUNCTION(DevFunction)
	void Launch(AHazePlayerCharacter Target)
	{
		bLaunched = true;
		TargetPlayer = Target;
		Timer = 0.0;

		SetActorTickEnabled(true);

		OriginalLaunchDirection = (Target.ActorLocation - ActorLocation).GetSafeNormal();
		ActorRotation = FRotator::MakeFromX(OriginalLaunchDirection);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bLaunched)
			return;

		FVector TargetVector = (TargetPlayer.ActorLocation - ActorLocation).GetSafeNormal();
		if (TargetVector.DotProduct(OriginalLaunchDirection) > 0)
		{
			ActorRotation = Math::RInterpConstantShortestPathTo(
				ActorRotation,
				FRotator::MakeFromX(TargetVector),
				DeltaSeconds,
				TurnRate,
			);
		}

		ActorLocation += ActorForwardVector * Speed * DeltaSeconds;
		
		Timer += DeltaSeconds;
		if (Timer > Lifetime)
		{
			if (bDestroyOnExpire)
				DestroyActor();
			else
				AddActorDisable(this);
		}
	}
};