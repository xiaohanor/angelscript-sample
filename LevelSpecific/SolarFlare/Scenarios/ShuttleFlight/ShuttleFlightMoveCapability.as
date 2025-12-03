class UShuttleFlightMoveCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"ShuttleFlightMoveCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	// UShuttleFlightUserComponent UserComp;
	USweepingMovementData Movement;
	FHazeAcceleratedVector AccelVector;
	FRotator CurrentRot;
	ASolarFlareShuttle Shuttle;

	float StrafeSpeed = 4000.0;
	float ForwardSpeed = 4000.0; 

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		// UserComp = UShuttleFlightUserComponent::GetOrCreate(Player);

		Shuttle = TListedActors<ASolarFlareShuttle>().GetSingle();
		Movement = Shuttle.MoveComp.SetupSweepingMovementData();
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
		CurrentRot = Shuttle.MeshRoot.RelativeRotation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!Shuttle.MoveComp.PrepareMove(Movement))
			return;

		if (HasControl())
		{
			FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
			FVector Direction;

			// Direction += Shuttle.ActorUpVector * Input.X; 
			Direction += Shuttle.ActorRightVector * Input.Y;
			Direction.Normalize(); 
			FVector TargetVelocity = Direction * StrafeSpeed;
			AccelVector.AccelerateTo(TargetVelocity, 0.75, DeltaTime);

			Movement.AddVelocity(AccelVector.Value);

			//TILT
			// float Roll = Direction.Y * 15.0;
			// float Yaw = Input.Y * 5.0;
			// float Pitch = Input.X * 3.0;
			// FRotator TargetRot = FRotator(Pitch, Yaw, Roll);
			// CurrentRot = Math::QInterpConstantTo(CurrentRot.Quaternion(), TargetRot.Quaternion(), DeltaTime, 0.75).Rotator();
			// Shuttle.MeshRoot.RelativeRotation = CurrentRot;
		}
		
		Shuttle.MoveComp.ApplyMove(Movement);
	}
}