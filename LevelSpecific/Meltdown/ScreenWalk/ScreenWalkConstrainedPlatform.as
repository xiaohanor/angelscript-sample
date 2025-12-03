class AScreenWalkConstrainedPlatform : AHazeActor
{
//	UPROPERTY(DefaultComponent, RootComponent)
//	UFauxPhysicsSplineFollowComponent RootSplineFollow;
//	default RootSplineFollow.NetworkMode = EFauxPhysicsSplineFollowNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = Rotation)
	UFauxPhysicsForceComponent Force;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UFauxPhysicsSplineFollowComponent CartSpline;
	
	UPROPERTY(DefaultComponent, Attach = Rotation)
	UFauxPhysicsWeightComponent CartWeight;

	UPROPERTY(DefaultComponent, Attach = CartSpline)
	UFauxPhysicsAxisRotateComponent Rotation;

	UPROPERTY(DefaultComponent, Attach = Rotation)
	UStaticMeshComponent Platform;

	UPROPERTY(DefaultComponent)
	UMeltdownScreenWalkResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent, Attach = Rotation)
	UNiagaraComponent Sparks;

	UPROPERTY(DefaultComponent, Attach = Rotation)
	USceneComponent HookPulley;

	FHazeAcceleratedFloat CartSpeedIncrease;

	bool bHasStomped;

	float RotationVelocity = 0.0;
	float RotationAngle = 0.0;
	FVector LastWorldLocation;

	FVector LastSplineLocation;

	FVector Velocity;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;

	float SplineEnd;
	float SplineStart = 0;

	float SPlineDistance;

	UHazeSplineComponent SplineComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LastWorldLocation = ActorLocation;

		ResponseComp.OnStompedTrigger.AddUFunction(this, n"StompedDown");

	}

	UFUNCTION()
	private void StompedDown()
	{
		FauxPhysics::ApplyFauxImpulseToParents(Force, FVector::ForwardVector * 6000.0);
		UMeltdownScreenWalkMineCartEventHandler::Trigger_StompImpact(this, FMeltdownScreenWalkHookSpot(HookPulley));
		UMeltdownScreenWalkMineCartEventHandler::Trigger_StartSparks(this, FMeltdownScreenWalkHookSpot(HookPulley));
		bHasStomped = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
		FQuat BaseRotation = Rotation.ComponentQuat * FQuat(FVector::RightVector, RotationAngle);
		FVector RotationDown = BaseRotation.RotateVector(-Rotation.UpVector);
		FVector RotationTangent = BaseRotation.RotateVector(Rotation.ForwardVector);

		RotationVelocity -= (ActorLocation - LastWorldLocation).DotProduct(RotationTangent) / 100.0;
		RotationVelocity *= Math::Pow(0.25, DeltaSeconds);
		RotationVelocity -= RotationAngle * 20.0 * DeltaSeconds;

		RotationAngle += RotationVelocity * DeltaSeconds;

		auto CartSPlinePosition = CartSpline.SplinePosition.CurrentSplineDistance;

		Velocity = CartSpline.WorldLocation - LastSplineLocation;

	//	Velocity = Velocity.ConstrainToDirection(CartSpline.GetForwardVector());

		PrintToScreen("" + Velocity.Size());

		if (Velocity.Size() <= 0.1 && !bHasStomped)
			UMeltdownScreenWalkMineCartEventHandler::Trigger_StopSparks(this);
			

		float Constraint = 0.4 * PI;
		if (RotationAngle < -Constraint)
		{
			RotationAngle = -Constraint;
			if (RotationVelocity < 0)
				RotationVelocity = -0.5 * RotationVelocity;
		}
		else if (RotationAngle > Constraint)
		{
			RotationAngle = Constraint;
			if (RotationVelocity > 0)
				RotationVelocity = -0.5 * RotationVelocity;
		}

		LastSplineLocation = CartSpline.WorldLocation;
		LastWorldLocation = ActorLocation;
		RotationRoot.SetRelativeRotation(FQuat(FVector::RightVector, RotationAngle));
		bHasStomped = false;
	}
};