class USkylineSentryDroneWhipDragCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SkylineDroneWhipDrag");

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
		if (!IsDragged())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsDragged())
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

		SentryDrone.bShouldStabilize = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PrintToScreen("Dragged", 0.0, FLinearColor::Green);

		FVector Force;

		for (auto& Grab : GravityWhipResponseComponent.Grabs)
			Force += Grab.TargetComponent.ConsumeForce();

		FVector Torque = SentryDrone.ActorTransform.InverseTransformVectorNoScale(SentryDrone.ActorForwardVector.CrossProduct(Force.GetSafeNormal()) * Settings.DragModeTorqueScale)
					   + SentryDrone.ActorTransform.InverseTransformVectorNoScale(SentryDrone.ActorUpVector.CrossProduct(SentryDrone.MovementWorldUp) * Settings.DragModeTorqueScale)
					   - SentryDrone.AngularVelocity * Settings.DragModeAngularDrag;

		SentryDrone.AngularVelocity += Torque * DeltaTime;

		if(MovementComponent.PrepareMove(Movement))
		{
			FVector Velocity = MovementComponent.Velocity;

			FVector Acceleration = Force * Settings.DragModeForceScale
								 - MovementComponent.Velocity * Settings.DragModeDrag;
				
			Movement.AddVelocity(Velocity);
			Movement.AddAcceleration(Acceleration);
			Movement.BlockGroundTracingForThisFrame();
			Movement.SetRotation(SentryDrone.GetMovementRotation(DeltaTime));

			MovementComponent.ApplyMove(Movement);
		}	
	}

	bool IsDragged() const
	{
		return (GravityWhipResponseComponent.GrabMode == EGravityWhipGrabMode::Drag && GravityWhipResponseComponent.Grabs.Num() > 0);
	}
}