
class UBasicAISimpleGroundMovementCapability : UBasicAIMovementCapability
{	
	default CapabilityTags.Add(n"GroundMovement");	

	UGroundPathfollowingSettings GroundPathfollowingSettings;
	USimpleMovementData SimpleMovement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GroundPathfollowingSettings = UGroundPathfollowingSettings::GetSettings(Owner);
		SimpleMovement = Cast<USimpleMovementData>(Movement);
	}

	UBaseMovementData SetupMovementData() override
	{
		return MoveComp.SetupSimpleMovementData();
	} 

	bool PrepareMove() override
	{
		return MoveComp.PrepareMove(SimpleMovement);
	}

	void ApplyCrumbSyncedMovement(FVector Velocity) override
	{
		Movement.ApplyCrumbSyncedGroundMovementWithCustomVelocity(Velocity);			
	}

	void ComposeMovement(float DeltaTime) override
	{	
		FVector OwnLoc = Owner.ActorLocation;
		FVector Velocity = MoveComp.Velocity;
		Velocity -= CustomVelocity; 

		FVector Destination = GetCurrentDestination();
		FVector HorizontalVelocity = Velocity.ConstrainToPlane(MoveComp.WorldUp);
		FVector VerticalVelocity = Velocity - HorizontalVelocity;
		FVector MoveDir = (Destination - OwnLoc).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		
		if (DestinationComp.HasDestination()) 
		{
			float MoveSpeed = DestinationComp.Speed;
			FHazeAcceleratedVector AccLocation;
			AccLocation.SnapTo(OwnLoc, HorizontalVelocity);

			if (IsMovingToFinalDestination() && OwnLoc.IsWithinDist(Destination, PathingSettings.AtDestinationRange))
			{
				// Slow to a stop
				AccLocation.AccelerateTo(Destination, 1.0, DeltaTime);
				
				// Keep applying slowed down velocity until we're moving away from destination 
				// TODO: this can be handled better, but will at least stop overshoot sliding on slopes.
				if (MoveDir.DotProduct(HorizontalVelocity) > 0.0) 
					Movement.AddVelocity(HorizontalVelocity);

				// MoveTo is completed (note that this will usually mean this capability will deactivate)
				PathFollowingComp.ReportComplete(true);
			}
			else
			{
				// Move towards destination
				AccLocation.AccelerateTo(OwnLoc + MoveDir * MoveSpeed, GroundPathfollowingSettings.AccelerationDuration, DeltaTime); 
				Movement.AddVelocity(AccLocation.Velocity.GetClampedToMaxSize(MoveSpeed)); // Hacky clamp but this will be replaced
			}
		}
		else
		{
			// No destination, slow to a stop
			DestinationComp.ReportStopping();
			float Friction = MoveComp.IsInAir() ? MoveSettings.AirFriction : MoveSettings.GroundFriction;
			HorizontalVelocity -= HorizontalVelocity * Friction * DeltaTime;
			Movement.AddVelocity(HorizontalVelocity);
			VerticalVelocity -= VerticalVelocity * Friction * DeltaTime;
		}

		CustomVelocity += DestinationComp.CustomAcceleration * DeltaTime;
		float Friction = MoveComp.IsOnWalkableGround() ? MoveSettings.GroundFriction : MoveSettings.AirFriction;
		CustomVelocity -= CustomVelocity * Friction * DeltaTime;
		Movement.AddVelocity(CustomVelocity);

		// Turn towards focus?
		if (DestinationComp.Focus.IsValid())
			MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, MoveSettings.TurnDuration, DeltaTime, Movement);
		// Turn towards destination if still some ways off
		else if (DestinationComp.HasDestination() && !OwnLoc.IsWithinDist(Destination, PathingSettings.AtDestinationRange))
			MoveComp.RotateTowardsDirection(MoveDir, MoveSettings.TurnDuration, DeltaTime, Movement);
		// Slow to a stop
		else  
			MoveComp.StopRotating(MoveSettings.StopTurningDamping, DeltaTime, Movement);

		Movement.AddPendingImpulses();
		Movement.AddVelocity(VerticalVelocity);
		Movement.AddGravityAcceleration();
	}
}
