class USkylineSentryDroneWhipSlingCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SkylineDroneWhipSling");

	UGravityWhipResponseComponent GravityWhipResponseComponent;
	UHazeMovementComponent MovementComponent;

	USweepingMovementData Movement;
	
	ASkylineSentryDrone SentryDrone;

	USkylineSentryDroneSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = USkylineSentryDroneSettings::GetSettings(Owner);

		GravityWhipResponseComponent = UGravityWhipResponseComponent::Get(Owner);
		MovementComponent = UHazeMovementComponent::Get(Owner);
		Movement = MovementComponent.SetupSweepingMovementData();

		SentryDrone = Cast<ASkylineSentryDrone>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!IsSlinged())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsSlinged())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(n"SkylineDroneMovement", this);
		Owner.BlockCapabilities(n"SkylineDroneHover", this);
		Owner.BlockCapabilities(n"SkylineDroneLookAt", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(n"SkylineDroneMovement", this);
		Owner.UnblockCapabilities(n"SkylineDroneHover", this);
		Owner.UnblockCapabilities(n"SkylineDroneLookAt", this);	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PrintToScreen("Slinging", 0.0, FLinearColor::Green);

		FVector AimDirection = (GravityWhipResponseComponent.AimLocation - SentryDrone.ActorLocation).GetSafeNormal();

		FVector Torque = SentryDrone.ActorTransform.InverseTransformVectorNoScale(SentryDrone.ActorForwardVector.CrossProduct(AimDirection) * Settings.SlingModeTorqueScale)
					   + SentryDrone.ActorTransform.InverseTransformVectorNoScale(SentryDrone.ActorUpVector.CrossProduct(GravityWhipResponseComponent.DesiredRotation.UpVector) * Settings.SlingModeTorqueScale)
					   - SentryDrone.AngularVelocity * Settings.SlingModeAngularDrag;

		SentryDrone.AngularVelocity += Torque * DeltaTime;

		if(MovementComponent.PrepareMove(Movement))
		{
			FVector Velocity = MovementComponent.Velocity;
			FVector Force;

			for (auto& Grab : GravityWhipResponseComponent.Grabs)
				Force += Grab.TargetComponent.ConsumeForce();

			FVector Acceleration = Force * Settings.SlingModeForceScale
								 - MovementComponent.Velocity * Settings.SlingModeDrag;
				
			Movement.AddVelocity(Velocity);
			Movement.AddAcceleration(Acceleration);
			Movement.BlockGroundTracingForThisFrame();
			Movement.SetRotation(SentryDrone.GetMovementRotation(DeltaTime));

			MovementComponent.ApplyMove(Movement);
		}
	}

	bool IsSlinged() const
	{
		return (GravityWhipResponseComponent.GrabMode == EGravityWhipGrabMode::Sling && GravityWhipResponseComponent.Grabs.Num() > 0);
	}
}