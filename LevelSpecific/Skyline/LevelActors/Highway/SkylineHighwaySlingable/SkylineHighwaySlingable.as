class ASkylineHighwaySlingable : AWhipSlingableObject
{
	default SlingSpeed = 20000;
	default HomingStrength = 1000;
	default LifeTimeAfterThrown = 1;
	default bSpawnHitEffectAfterLifetimeExpired = true;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY()
	UCameraShakePattern ExplodeCameraShake;

	UPROPERTY()
	UForceFeedbackEffect ExplodeForceFeedback;

	FVector StartLocation;
	FVector MidLocation;
	FVector EndLocation;
	FVector Direction;
	float Alpha;
	float RotationSpeed;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		StartLocation = ActorLocation;

		EndLocation = ActorLocation - Direction * 3000;
		EndLocation.Z = StartLocation.Z - 5000;

		MidLocation = ((StartLocation + EndLocation) / 2);
		MidLocation.Z = StartLocation.Z + Math::RandRange(2000, 3400);

		RotationSpeed = Math::RandRange(50, 250);
		
		OnWhipSlingableObjectImpact.AddUFunction(this, n"Impacted");
	}

	UFUNCTION()
	private void Impacted(TArray<FHitResult> HitResults, FVector Velocity)
	{
		Explode();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
		
		if(bGrabbed)
			return;
		if(bThrown)
			return;

		AddActorWorldRotation(FRotator(1, 1, 1) * DeltaSeconds * RotationSpeed);

		Alpha += DeltaSeconds * 0.2;
		FVector NewLocation = BezierCurve::GetLocation_1CP(StartLocation, MidLocation, EndLocation, Alpha);
		FVector Delta = NewLocation - ActorLocation;
		ActorLocation = NewLocation;

		bool bHit = false;
		if(!Delta.IsNearlyZero() && Delta.Z < 0)
		{
			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceMio);
			FHitResult Hit = Trace.QueryTraceSingle(Collision.WorldLocation, Collision.WorldLocation + Delta);
			bHit = Hit.bBlockingHit;
		}

		if(Alpha >= 1 || bHit)
		{
			Explode();
			if(HasControl())
				CrumbLifeTimeExpired();
		}
	}

	UFUNCTION(BlueprintEvent)
	void Explode()
	{

	}
}