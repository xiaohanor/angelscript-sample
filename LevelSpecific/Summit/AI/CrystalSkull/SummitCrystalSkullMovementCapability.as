class USummitCrystalSkullMovementCapability : UBasicAIMovementCapability
{	
	default CapabilityTags.Add(n"FlyingMovement");	

	USimpleMovementData SlidingMovement;
	USummitCrystalSkullSettings FlyerSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		SlidingMovement = Cast<USimpleMovementData>(Movement);
		FlyerSettings = USummitCrystalSkullSettings::GetSettings(Owner);
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
		float Friction = MoveSettings.AirFriction;

		FVector Destination = GetCurrentDestination();

		FVector ToDest = (Destination - OwnLoc);
		float DestDist = ToDest.Size();
		FVector DestDir = (DestDist > 1.0) ? ToDest / DestDist : Owner.ActorForwardVector;
		if (DestinationComp.HasDestination() && (DestDist > 1.0))
		{
			// Plain acceleration towards destination, precision is not important
			Velocity += DestDir * DestinationComp.Speed * DeltaTime;
		}
		else
		{
			// No destination, let friction slow us to a stop 
			DestinationComp.ReportStopping();
		}

		// Apply friction
		Velocity -= Velocity * Friction * DeltaTime;
	
		Movement.AddVelocity(Velocity);

		CustomVelocity += DestinationComp.CustomAcceleration * DeltaTime;
		CustomVelocity -= CustomVelocity * Friction * DeltaTime;
		Movement.AddVelocity(CustomVelocity);

		// Turn towards focus or direction of move
		if (DestinationComp.Focus.IsValid())
			MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, FlyerSettings.TurnDuration, DeltaTime, Movement);
		else if (DestinationComp.HasDestination() && !OwnLoc.IsWithinDist(Destination, PathingSettings.AtDestinationRange))
			MoveComp.RotateTowardsDirection(DestDir, FlyerSettings.TurnDuration, DeltaTime, Movement);
		else  
			MoveComp.StopRotating(MoveSettings.StopTurningDamping, DeltaTime, Movement);

		Movement.AddPendingImpulses();

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(Destination, OwnLoc, FLinearColor::LucBlue);		
			Debug::DrawDebugLine(OwnLoc, OwnLoc + Velocity, FLinearColor::Green);		
		}
#endif
	}
}
