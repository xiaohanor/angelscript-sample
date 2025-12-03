event void FSummitFlyingGemEnemySignature();

class ASummitFlyingGemEnemy : AHazeActor
{

    UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SummitFlyingGemEnemyAttackCapability");
	
	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComponent;

	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent Collision;
    default Collision.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

    UPROPERTY()
	TSubclassOf<ASummitMagicTrajectoryProjectile> ProjectileClass;

	UPROPERTY(DefaultComponent, Attach = Collision)
	USceneComponent BobbingRoot;

    UPROPERTY(DefaultComponent, Attach = BobbingRoot)
	USceneComponent VerticalAttackPos;

    UPROPERTY(DefaultComponent, Attach = BobbingRoot)
	USceneComponent Wings;

    UPROPERTY(DefaultComponent, Attach = Wings)
	USceneComponent LeftWingPivot;
	UPROPERTY(DefaultComponent, Attach = LeftWingPivot)
	USceneComponent LeftWing;

	UPROPERTY(DefaultComponent, Attach = Wings)
	USceneComponent RightWingPivot;
    UPROPERTY(DefaultComponent, Attach = RightWingPivot)
	USceneComponent RightWing;

    UPROPERTY(DefaultComponent, Attach = BobbingRoot)
	USceneComponent AttackOrigin;
	
	UPROPERTY(EditAnywhere)
	bool bProjectileAttacks = true;

	UPROPERTY(EditAnywhere)
	ASummitFlyingGemEnemyVerticalAttack VerticalAttack;

    UPROPERTY(EditAnywhere)
    ANightQueenMetal MetalWingOneActor;

    UPROPERTY(EditAnywhere)
    ANightQueenMetal MetalWingTwoActor;

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;
	UHazeSplineComponent Spline;
	float DistanceAlongSpline;

    UPROPERTY(EditAnywhere)
	float TravelDuration = 5.0;

	UPROPERTY(EditAnywhere)
	FVector DestinationUpVector = FVector::UpVector;

	UPROPERTY()
	FSummitFlyingGemEnemySignature OnReachedDestination;
	FSummitFlyingGemEnemySignature OnActivated;
	FSummitFlyingGemEnemySignature OnDefeated;

	FHazeTimeLike MoveAnimation;	
	default MoveAnimation.Duration = 1.0;
	default MoveAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default MoveAnimation.Curve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve Speed;
	default Speed.AddDefaultKey(0.0, 0.0);
	default Speed.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve Rotation;
	default Rotation.AddDefaultKey(0.0, 0.0);
	default Rotation.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	float BobHeight = 150.0;

	UPROPERTY(EditAnywhere)
	float BobSpeed = 5.0;

	UPROPERTY(EditAnywhere)
	float BobOffset = 0.0;

	UPROPERTY(EditAnywhere)
	float DeathRotationSpeed = 2;

	UPROPERTY(EditAnywhere)
    float RotationSpeed = 0.8;

    bool bDefeated;
    bool bIsActive;
	bool bReachedDestination;

	float DestructionTimer = 8;


	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(SplineActor != nullptr)
		{
			Spline = SplineActor.Spline;
			OnUpdate(1.0);
		}
        if (MetalWingOneActor != nullptr)
            MetalWingOneActor.AttachToComponent(LeftWing);
		if (MetalWingTwoActor != nullptr)
            MetalWingTwoActor.AttachToComponent(RightWing);
		if (!bProjectileAttacks) {
			if (VerticalAttack != nullptr) {
				VerticalAttack.AttachToComponent(VerticalAttackPos);
			}
		}

	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
        if (MetalWingOneActor != nullptr)
            MetalWingOneActor.AttachToComponent(LeftWing);
		if (MetalWingTwoActor != nullptr)
            MetalWingTwoActor.AttachToComponent(RightWing);
		if (!bProjectileAttacks) {
			if (VerticalAttack != nullptr) {
				VerticalAttack.AttachToComponent(VerticalAttackPos);
			}
		}

        Spline = SplineActor.Spline;
		OnUpdate(0.0);
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");
		MoveAnimation.SetPlayRate(1.0 / TravelDuration);

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{

        if (!bDefeated) {
			BobbingRoot.SetRelativeLocation(FVector::UpVector * Math::Sin((Time::GameTimeSeconds * BobSpeed + BobOffset)) * BobHeight);

            if (MetalWingOneActor != nullptr) {
				if (MetalWingOneActor.bMelted) {
					Defeated();
				}
			}

        }
		if (bDefeated) {
			BobbingRoot.AddRelativeRotation(FRotator(40 * DeltaTime, (720 * DeltaTime) * -1, 720 * DeltaTime));

			DestructionTimer = DestructionTimer - DeltaTime;

			if (DestructionTimer <= 0)
				DestroyActor();
		}

	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		if (bDefeated)
			return;
		
		DistanceAlongSpline = Spline.SplineLength * Speed.GetFloatValue(Alpha);

		FTransform TransformAtDistance = Spline.GetWorldTransformAtSplineDistance(DistanceAlongSpline);
		FVector CurrentLocation = TransformAtDistance.Location;
		FQuat CurrentRotation = FQuat::Slerp(TransformAtDistance.Rotation, FQuat::MakeFromZX(DestinationUpVector, TransformAtDistance.Rotation.ForwardVector), Rotation.GetFloatValue(Alpha));

		SetActorLocationAndRotation(CurrentLocation, CurrentRotation);
	}

    UFUNCTION()
	void OnFinished()
	{
		OnReachedDestination.Broadcast();
		bReachedDestination = true;

		if (!bProjectileAttacks) {
			if (VerticalAttack != nullptr) {
				VerticalAttack.Activate();
			}
		}
	}

	UFUNCTION()
	void Activate()
	{
		MoveAnimation.Play();
        bIsActive = true;
		
		BP_Activate();

	}

	UFUNCTION(BlueprintEvent)
	void BP_Activate()
	{

	}

	UFUNCTION()
	void Deactivate()
	{
		MoveAnimation.Stop();
        bIsActive = false;

		BP_Deactivate();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Deactivate()
	{

	}

    UFUNCTION()
	void Defeated()
	{
        if (bDefeated)
            return;

        Collision.SetSimulatePhysics(true);
        bDefeated = true;
        bIsActive = false;

		if (!bProjectileAttacks) {
			if (VerticalAttack != nullptr) {
				VerticalAttack.Deactivate();
			}
		}

		OnDefeated.Broadcast();

	}

	void SpawnProjectile(AHazeActor Target)
	{
        if (!bIsActive)
            return;
        
		FRotator RotTarget = (Target.ActorLocation - AttackOrigin.WorldLocation).Rotation();

		ASummitMagicTrajectoryProjectile Proj = SpawnActor(ProjectileClass, AttackOrigin.WorldLocation, RotTarget, bDeferredSpawn = true);
		Proj.IgnoreActors.Add(this);
		Proj.TargetLocation = Target.ActorLocation;
		Proj.Speed = 8200.0;
		Proj.Gravity = 1200.0;
		FinishSpawningActor(Proj);
	}

}