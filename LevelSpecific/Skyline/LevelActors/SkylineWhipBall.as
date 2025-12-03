class ASkylineWhipBall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent Collision;

	UPROPERTY(DefaultComponent, Attach = Collision)
	UGravityWhipTargetComponent GravityWhipTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityWhipTargetComponent)
	UTargetableOutlineComponent GravityWhipOutlineComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent GravityWhipResponseComponent;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComponent;

	USweepingMovementData Movement;

	float Drag = 1.0;

	FVector ReleaseImpulse;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
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
			UMovementStandardSettings::SetWalkableSlopeAngle(this, 90.0, this, EHazeSettingsPriority::Defaults);
		}

		// Set up ground trace
		// {
		// 	UMovementSweepingSettings::SetGroundedTraceDistance(this, FMovementSettingsValue::MakeValue(1.0), this, EHazeSettingsPriority::Defaults);
		// }

		Movement = MovementComponent.SetupSweepingMovementData();

		GravityWhipResponseComponent.OnReleased.AddUFunction(this, n"OnReleased");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(MovementComponent.PrepareMove(Movement))
		{
			FVector Velocity = MovementComponent.Velocity;
		//	Velocity += ReleaseImpulse;
			FVector Force;

			for (auto& Grab : GravityWhipResponseComponent.Grabs)
				Force += Grab.TargetComponent.ConsumeForce();

			FVector Acceleration = Force * 1.0
								+ ConsumeImpulse()
								- MovementComponent.Velocity * Drag;

			if (GravityWhipResponseComponent.Grabs.Num() == 0)
				Acceleration += FVector::UpVector * -980.0 * MovementComponent.GravityMultiplier;

			Movement.AddVelocity(Velocity);
			Movement.AddAcceleration(Acceleration);
			Movement.BlockGroundTracingForThisFrame();
			MovementComponent.ApplyMove(Movement);
		}		
	}

	UFUNCTION()
	private void OnReleased(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		FVector Impulse)
	{
		ReleaseImpulse = Impulse;
	}

	FVector ConsumeImpulse()
	{
		FVector Impulse = ReleaseImpulse * 30.0;
//		PrintScaled("Impulse: " + Impulse, 2.0, FLinearColor::Green, 5.0);
		ReleaseImpulse = FVector::ZeroVector;
		return Impulse;
	}
}