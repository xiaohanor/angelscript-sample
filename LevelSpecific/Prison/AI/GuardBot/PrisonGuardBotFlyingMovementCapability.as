class UPrisonGuardBotFlyingMovementCapability : UBasicAIMovementCapability
{	
	default CapabilityTags.Add(n"FlyingMovement");	

	USimpleMovementData SlidingMovement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		SlidingMovement = Cast<USimpleMovementData>(Movement);
	}

	UBaseMovementData SetupMovementData() override
	{
		return MoveComp.SetupSimpleMovementData();
	} 

	bool PrepareMove() override
	{
		return MoveComp.PrepareMove(SlidingMovement);
	}

	void ComposeMovement(float DeltaTime) override
	{
		FVector OwnLoc = Owner.ActorLocation;
		FVector Velocity = MoveComp.Velocity;
		Velocity -= CustomVelocity;
		float Friction = MoveSettings.AirFriction;

		FVector Destination = GetCurrentDestination();

		FVector ToDest = (Destination - OwnLoc);
		float DestDist = ToDest.Size();
		FVector DestDir = (DestDist > 1.0) ? ToDest / DestDist : Owner.ActorForwardVector;
		if (DestinationComp.HasDestination() && (DestDist > 1.0))
		{
			float Acceleration = DestinationComp.Speed;

			// Accelerate right/left to turn towards destination if we're off
			FVector CurDir = Velocity.IsNearlyZero(10.0) ? Owner.ActorForwardVector : Velocity.GetSafeNormal();
			float DestAccFactor = 1.0;
			if (CurDir.DotProduct(DestDir) < 1.0 - SMALL_NUMBER)
			{
				FVector TurnPlaneNormal = CurDir.CrossProduct(DestDir);
				FVector TurnCross = TurnPlaneNormal.CrossProduct(CurDir);
				Movement.AddAcceleration(TurnCross * Acceleration);
				DestAccFactor = 1.0 - TurnCross.Size();
			}

			// Accelerate directly towards destination with remaining acceleration fraction
			Movement.AddAcceleration(DestDir * Acceleration * DestAccFactor);
		}
		else
		{
			// No destination, let friction slow us to a stop 
			DestinationComp.ReportStopping();
		}

		// Apply friction
		Movement.AddAcceleration(-Velocity * Friction);
	
		// Bob a bit
		Movement.AddAcceleration(FVector::UpVector * Math::Sin(ActiveDuration * 1.79) * 200.0);
		Movement.AddAcceleration(Owner.ActorRightVector * Math::Sin(ActiveDuration * 1.27) * 100.0);

		Movement.AddVelocity(Velocity);

		CustomVelocity += DestinationComp.CustomAcceleration * DeltaTime;
		CustomVelocity -= CustomVelocity * Friction * DeltaTime;
		Movement.AddVelocity(CustomVelocity);

		// Turn towards focus or direction of move
		if (DestinationComp.Focus.IsValid())
			MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, MoveSettings.TurnDuration, DeltaTime, Movement);
		else if (DestinationComp.HasDestination() && !OwnLoc.IsWithinDist(Destination, PathingSettings.AtDestinationRange))
			MoveComp.RotateTowardsDirection(DestDir, MoveSettings.TurnDuration, DeltaTime, Movement);
		else  
			MoveComp.StopRotating(MoveSettings.StopTurningDamping, DeltaTime, Movement);

		Movement.AddPendingImpulses();
	}
}
