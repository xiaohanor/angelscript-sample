class USkylineSentryDroneFallingCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SkylineDroneFalling");

	UHazeMovementComponent MovementComponent;

	USweepingMovementData Movement;

	ASkylineSentryDrone SentryDrone;

	USkylineSentryDroneSettings Settings;

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
		if (!SentryDrone.bIsThrown)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SentryDrone.bIsThrown)
			return true;

		if (ActiveDuration > Settings.FallingTimeBeforeStabilization + SentryDrone.DisableTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(n"SkylineDroneStabilize", this);
		Owner.BlockCapabilities(n"SkylineDroneMovement", this);
		Owner.BlockCapabilities(n"SkylineDroneHover", this);
		Owner.BlockCapabilities(n"SkylineDroneLookAt", this);

		Owner.BlockCapabilities(n"SkylineSentryDroneTurretTargeting", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(n"SkylineDroneStabilize", this);	
		Owner.UnblockCapabilities(n"SkylineDroneMovement", this);	
		Owner.UnblockCapabilities(n"SkylineDroneHover", this);	
		Owner.UnblockCapabilities(n"SkylineDroneLookAt", this);	
	
		Owner.UnblockCapabilities(n"SkylineSentryDroneTurretTargeting", this);	

		SentryDrone.bIsThrown = false;
		SentryDrone.bShouldStabilize = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PrintToScreen("Falling", 0.0, FLinearColor::Green);

		FVector Torque = -SentryDrone.AngularVelocity * Settings.FallingAngularDrag;

		SentryDrone.AngularVelocity += Torque * DeltaTime;

		if(MovementComponent.PrepareMove(Movement))
		{
			FVector Velocity = MovementComponent.Velocity;

			FVector Acceleration = -MovementComponent.WorldUp * Settings.FallingGravity
								 - MovementComponent.Velocity * Settings.FallingDrag;
				
			Movement.AddVelocity(Velocity);
			Movement.AddAcceleration(Acceleration);
			Movement.BlockGroundTracingForThisFrame();
			Movement.SetRotation(SentryDrone.GetMovementRotation(DeltaTime));

			MovementComponent.ApplyMove(Movement);
		}
	}
}