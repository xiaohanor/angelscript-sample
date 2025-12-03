class USkylineSentryDroneHoverCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SkylineDroneHover");
	default CapabilityTags.Add(n"SkylineDroneMovement");

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
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PrintToScreen("Hovering", 0.0, FLinearColor::Green);

		if(MovementComponent.PrepareMove(Movement))
		{
			FVector Velocity = MovementComponent.Velocity;
			FVector Force;

			FVector Acceleration = Force * Settings.HoverForceScale
								 - MovementComponent.Velocity * Settings.HoverDrag;
				
			Movement.AddVelocity(Velocity);
			Movement.AddAcceleration(Acceleration);
			Movement.BlockGroundTracingForThisFrame();
			Movement.SetRotation(SentryDrone.GetMovementRotation(DeltaTime));

			MovementComponent.ApplyMove(Movement);
		}
	}
}