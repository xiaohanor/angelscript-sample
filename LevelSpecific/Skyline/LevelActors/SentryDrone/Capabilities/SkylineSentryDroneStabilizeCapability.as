class USkylineSentryDroneStabilizeCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SkylineDroneStabilize");

	UHazeMovementComponent MovementComponent;

	USweepingMovementData Movement;

	ASkylineSentryDrone SentryDrone;

	USkylineSentryDroneSettings Settings;

	FVector StabilizeLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = USkylineSentryDroneSettings::GetSettings(Owner);

		MovementComponent = UHazeMovementComponent::Get(Owner);
		Movement = MovementComponent.SetupSweepingMovementData();

		SentryDrone = Cast<ASkylineSentryDrone>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SentryDrone.bShouldStabilize)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SentryDrone.bShouldStabilize)
			return true;

		if (ActiveDuration >= Settings.StabilizeTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(n"SkylineDroneFalling", this);
		Owner.BlockCapabilities(n"SkylineDroneMovement", this);
		Owner.BlockCapabilities(n"SkylineDroneHover", this);
		Owner.BlockCapabilities(n"SkylineDroneLookAt", this);

		Owner.BlockCapabilities(n"SkylineSentryDroneTurret", this);

		StabilizeLocation = SentryDrone.ActorLocation + SentryDrone.MovementWorldUp * 300.0;		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(n"SkylineDroneFalling", this);	
		Owner.UnblockCapabilities(n"SkylineDroneMovement", this);	
		Owner.UnblockCapabilities(n"SkylineDroneHover", this);	
		Owner.UnblockCapabilities(n"SkylineDroneLookAt", this);	

		Owner.UnblockCapabilities(n"SkylineSentryDroneTurret", this);

		SentryDrone.bIsThrown = false;
		SentryDrone.bShouldStabilize = false;
		SentryDrone.DisableTime = 0.0;
		SentryDrone.bHadImpact = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PrintToScreen("Stabilizing", 0.0, FLinearColor::Green);

		FVector Torque = SentryDrone.ActorTransform.InverseTransformVectorNoScale(SentryDrone.ActorUpVector.CrossProduct(SentryDrone.MovementWorldUp) * Settings.StabilizeTorqueScale)
					   + SentryDrone.ActorTransform.InverseTransformVectorNoScale(SentryDrone.ActorUpVector * 30.0)
					   - SentryDrone.AngularVelocity * Settings.StabilizeAngularDrag;

		SentryDrone.AngularVelocity += Torque * DeltaTime;

		if(MovementComponent.PrepareMove(Movement))
		{
			FVector Velocity = MovementComponent.Velocity;
			FVector Force;

			FVector ToTarget = StabilizeLocation - SentryDrone.ActorLocation;

			float MovementAcceleration = Math::Min(Settings.StabilizeMaxAcceleration, ToTarget.Size());

			FVector Acceleration = ToTarget.GetSafeNormal() * MovementAcceleration
								 - MovementComponent.Velocity * 2.0;
				
			Movement.AddVelocity(Velocity);
			Movement.AddAcceleration(Acceleration);
			Movement.BlockGroundTracingForThisFrame();
			Movement.SetRotation(SentryDrone.GetMovementRotation(DeltaTime));

			MovementComponent.ApplyMove(Movement);
		}
	}
}