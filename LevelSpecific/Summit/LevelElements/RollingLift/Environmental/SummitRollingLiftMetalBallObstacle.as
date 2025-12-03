asset SummitRollingLiftMetalBallGravitySettings of UMovementGravitySettings
{
	GravityAmount = 2000.0;

	TerminalVelocity = 10000.0;
}

class ASummitRollingLiftMetalBallObstacle : ANightQueenMetal
{
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UHazeSphereCollisionComponent SphereCollision;
	default SphereCollision.SetCollisionProfileName(n"BlockAll");
	default SphereCollision.SphereRadius = 50.0;

	default CapabilityComp.DefaultCapabilities.Add(n"SummitRollingLiftMetalBallObstacleMovementCapability");

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;
	default MoveComp.bApplyInitialCollisionShapeAutomatically = false;
	
	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ASplineActor SplineToFollow;

	/** Gem Boulder which gets attached to the rotating mesh of this actor */
	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ASummitNightQueenGem GemBoulderActor;

	/** How fast the ball moves along the spline as a base */
	UPROPERTY(EditAnywhere, Category = "Settings")
	float BaseSpeed = 2000.0;

	/** How fast it accelerates towards the base speed */
	UPROPERTY(EditAnywhere, Category = "Settings")
	float StartAcceleration = 0.5;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float KnockbackImpulse = 4000.0;

	default BlockingVolume.CollisionEnabled = ECollisionEnabled::NoCollision;

	bool bIsRolling = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		MoveComp.SetupShapeComponent(SphereCollision);

		ApplyDefaultSettings(SummitRollingLiftMetalBallGravitySettings);

		if(GemBoulderActor != nullptr)
			GemBoulderActor.AttachToComponent(MeshComp, n"None", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);

		FVector SplineLocation = SplineToFollow.Spline.GetClosestSplineWorldLocationToWorldLocation(ActorLocation);
		SplineLocation.Z = ActorLocation.Z;
		SetActorLocation(SplineLocation);
	}

	UFUNCTION(BlueprintCallable)
	void StartRolling()
	{
		bIsRolling = true;
	}
}