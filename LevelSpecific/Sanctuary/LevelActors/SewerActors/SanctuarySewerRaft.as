class ASanctuarySewerRaft : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent WorldCollision;

	UPROPERTY(DefaultComponent, Attach = WorldCollision)
	UFauxPhysicsConeRotateComponent PhysicsRoot;

	UPROPERTY(DefaultComponent, Attach = PhysicsRoot)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent RaftMesh;

	// UPROPERTY(DefaultComponent, Attach = MeshRoot)
	// UDarkPortalTargetComponent DarkPortalTargetComp;


	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComponent;


	USimpleMovementData Movement;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent PortalResponseComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalFauxPhysicsReactionComponent DarkPortalFauxPhysicsReactionComp;

	// UPROPERTY(DefaultComponent)
	// USanctuarySewerFloatingComponent SewerFloatingComp;

	UPROPERTY(EditAnywhere)
	ASanctuarySewerWater SewerWater;


	UPROPERTY(EditAnywhere)
	ARespawnPoint RespawnPoint;

	float Drag = 1;
	float PullForceMultiplier = 1;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		Movement = MovementComponent.SetupSimpleMovementData();
		AttachToComponent(SewerWater.WaterRoot, NAME_None, EAttachmentRule::KeepWorld);
		if(RespawnPoint != nullptr)
			RespawnPoint.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld);

		// Setup the resolver
		{	
			UMovementResolverSettings::SetMaxRedirectIterations(this, 3, this, EHazeSettingsPriority::Defaults);
			UMovementResolverSettings::SetMaxDepenetrationIterations(this, 2, this, EHazeSettingsPriority::Defaults);
		}

		// Override the gravity settings
		{
			UMovementGravitySettings::SetGravityScale(this, 3, this, EHazeSettingsPriority::Defaults);
		}

		// Everything is sliding
		{
			UMovementStandardSettings::SetWalkableSlopeAngle(this, 0, this, EHazeSettingsPriority::Defaults);
		}

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{	
		FVector PullForce;
		for(auto Grab : PortalResponseComp.Grabs)
		{
			PullForce += Grab.PreviousForce * PullForceMultiplier;
		}

		float HeightDifference = SewerWater.WaterRoot.WorldLocation.Z - ActorLocation.Z;
		FVector Acceleration = PullForce.VectorPlaneProject(FVector::UpVector)
							+ FVector::UpVector * HeightDifference
							- MovementComponent.Velocity * Drag;


		if(MovementComponent.PrepareMove(Movement))
		{
			Movement.AddVelocity(FVector(MovementComponent.Velocity.X, MovementComponent.Velocity.Y, 0));

			Movement.AddAcceleration(Acceleration);
		//	Movement.SetRotation(Rotation);

			MovementComponent.ApplyMove(Movement);
		}

	}



	

};