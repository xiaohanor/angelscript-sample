class AEvergreenBall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UMovementResponseBallPhysicsComponent BallPhysics;

	UPROPERTY(DefaultComponent, Attach = BallPhysics)
	UStaticMeshComponent BallMesh;
	default BallMesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent, Attach = BallPhysics)
	USphereComponent Collision;
	default Collision.CollisionProfileName = n"BlockAllDynamic";
	default Collision.bGenerateOverlapEvents = false;

	UPROPERTY(EditAnywhere)
	AEvergreenLifeManager LifeManager;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY()
	float Speed = 800;

	UPROPERTY()
	float Gravity = 6000.0;

	UPROPERTY()
	float VinterpSpeed = 200;

	//Use this to multiply the speed value
	UPROPERTY()
	float AlphaValueFromLifeComponent;

	USweepingMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Movement = MoveComp.SetupSweepingMovementData();
		Collision.SphereRadius = BallPhysics.BallRadius;
		MoveComp.AddMovementIgnoresActor(this, Game::Mio);
		MoveComp.AddMovementIgnoresActor(this, Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				Movement.AddVelocity(ActorForwardVector * LifeManager.LifeComp.VerticalAlpha * Speed);
				Movement.AddVelocity(ActorRightVector * LifeManager.LifeComp.HorizontalAlpha * Speed);
				Movement.AddAcceleration(MoveComp.GravityDirection * Gravity);
				Movement.AddOwnerVerticalVelocity();

				// const float BouncebackMultiplier = 0.1;

				// if(!MoveComp.PreviousHadCeilingImpact() && MoveComp.HasCeilingImpact())
				// {
				// 	Movement.AddImpulse(MoveComp.CeilingImpact.ImpactNormal * -MoveComp.CeilingImpact.ImpactNormal.DotProduct(MoveComp.PreviousVelocity) * BouncebackMultiplier);
				// }
				// if(!MoveComp.PreviousHadWallImpact() && MoveComp.HasWallImpact())
				// {
				// 	Movement.AddImpulse(MoveComp.WallImpact.ImpactNormal * -MoveComp.WallImpact.ImpactNormal.DotProduct(MoveComp.PreviousVelocity) * BouncebackMultiplier);
				// }
				// if(!MoveComp.PreviousHadGroundImpact() && MoveComp.HasGroundImpact())
				// {
				// 	Movement.AddImpulse(MoveComp.GroundImpact.ImpactNormal * -MoveComp.GroundImpact.ImpactNormal.DotProduct(MoveComp.PreviousVelocity) * BouncebackMultiplier);
				// }
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);
		}

		// AlphaValueFromLifeComponent = LifeManager.LifeComp.HorizontalAlpha + LifeManager.LifeComp.VerticalAlpha;

		// // Speed = Speed * AlphaValueFromLifeComponent;
		// // PrintToScreen("AlphaValueFromLifeComponent"+AlphaValueFromLifeComponent, 2.f);

		// FVector NewLocation;
		// NewLocation = GetActorLocation() + (ActorForwardVector * LifeManager.LifeComp.VerticalAlpha) * (Speed * DeltaSeconds);
		// NewLocation += (ActorRightVector * LifeManager.LifeComp.HorizontalAlpha) * (Speed * DeltaSeconds);

		// SetActorLocation(NewLocation);
	}
};