class USkylineSentryDroneMoveToCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SkylineDroneMoveTo");
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
		if (SentryDrone.FollowTarget.IsDefaultValue())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (SentryDrone.FollowTarget.IsDefaultValue())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PrintToScreen("OnActivated MoveTo", 0.1, FLinearColor::Green);

		Owner.BlockCapabilities(n"SkylineDroneHover", this);
		Owner.BlockCapabilities(n"SkylineDroneLookAt", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(n"SkylineDroneHover", this);
		Owner.UnblockCapabilities(n"SkylineDroneLookAt", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	//	Debug::DrawDebugPoint(SentryDrone.FollowTarget.Get(), 20.0, FLinearColor::Green, 0.0);

		FVector ToTarget = SentryDrone.FollowTarget.Get() - SentryDrone.ActorLocation;

		float MovementAcceleration = Math::Min(Settings.MoveToMaxAcceleration, ToTarget.Size());

		FVector Torque = SentryDrone.ActorTransform.InverseTransformVectorNoScale(SentryDrone.ActorForwardVector.CrossProduct(ToTarget.GetSafeNormal()) * Settings.MoveToTorqueScale)
					   + SentryDrone.ActorTransform.InverseTransformVectorNoScale(SentryDrone.ActorUpVector.CrossProduct(SentryDrone.MovementWorldUp) * Settings.MoveToTorqueScale)		
					   - SentryDrone.AngularVelocity * Settings.MoveToAngularDrag;

		SentryDrone.AngularVelocity += Torque * DeltaTime;

		if(MovementComponent.PrepareMove(Movement))
		{
			FVector Velocity = MovementComponent.Velocity;

			FVector Acceleration = ToTarget.GetSafeNormal() * MovementAcceleration * Settings.MoveToForceScale
								 - MovementComponent.Velocity * Settings.MoveToDrag;
				
			Movement.AddVelocity(Velocity);
			Movement.AddAcceleration(Acceleration);
			Movement.BlockGroundTracingForThisFrame();
			Movement.SetRotation(SentryDrone.GetMovementRotation(DeltaTime));

			MovementComponent.ApplyMove(Movement);
		}	
	}
}