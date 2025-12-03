class USkylineGeckoGroundMovementCapability : UHazeCapability
{	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"GroundMovement");	
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	default DebugCategory = CapabilityTags::Movement;

	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UPathfollowingMoveToComponent PathFollowingComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UBasicAIAnimationComponent AnimComp;
	USkylineGeckoComponent GeckoComp;

	USkylineGeckoSettings Settings;
	UPathfollowingSettings PathingSettings;
	USimpleMovementData Movement;

    FVector CustomVelocity;
	FVector PrevLocation;
	FHazeAcceleratedRotator AccUp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestinationComp = UBasicAIDestinationComponent::GetOrCreate(Owner);
		PathFollowingComp = UPathfollowingMoveToComponent::GetOrCreate(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner); // This has to be created before MoveComp runs BeginPlay
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		GeckoComp = USkylineGeckoComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::GetOrCreate(Owner);
		Settings = USkylineGeckoSettings::GetSettings(Owner);
		PathingSettings = UPathfollowingSettings::GetSettings(Owner);
		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return false;
        return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		PrevLocation = Owner.ActorLocation;
		AccUp.SnapTo(MoveComp.WorldUp.Rotation());
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(!MoveComp.PrepareMove(Movement, AccUp.AccelerateTo(FRotator(90.0, 0.0, 0.0), 1.0, DeltaTime).Vector()))
			return;
		if(HasControl())
		{
			ComposeMovement(DeltaTime);
		}
		else
		{
			// Since we normally don't want to replicate velocity, we use move since last frame instead.
			// This can fluctuate wildly, introduce smoothing/velocity replication if necessary
			FVector Velocity = (DeltaTime > 0.0) ? (Owner.ActorLocation - PrevLocation) / DeltaTime : Owner.ActorVelocity;
			Movement.ApplyCrumbSyncedGroundMovementWithCustomVelocity(Velocity);			
		}

		PrevLocation = Owner.ActorLocation;
		MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimComp.FeatureTag);
		DestinationComp.bHasPerformedMovement = true;
	}

	void ComposeMovement(float DeltaTime)
	{	
		FVector OwnLoc = Owner.ActorLocation;
		FVector Velocity = MoveComp.Velocity;
		Velocity -= CustomVelocity; 

		FVector Destination = GetCurrentDestination();
		FVector HorizontalVelocity = Velocity.ConstrainToPlane(MoveComp.WorldUp);
		FVector VerticalVelocity = Velocity - HorizontalVelocity;
		FVector MoveDir = (Destination - OwnLoc).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();

		float Friction = MoveComp.IsOnWalkableGround() ? Settings.GroundFriction : Settings.AirFriction;
		float FrictionFactor = Math::Pow(Math::Exp(-Friction), DeltaTime);

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
				AccLocation.AccelerateTo(OwnLoc + MoveDir * MoveSpeed, 1.0, DeltaTime);
				const FVector ClampedVelocity = AccLocation.Velocity.GetClampedToMaxSize(MoveSpeed); // Hacky clamp but this will be replaced
				Movement.AddVelocity(ClampedVelocity);
			}
		}
		else
		{
			// No destination, slow to a stop
			DestinationComp.ReportStopping();
			HorizontalVelocity *= FrictionFactor;
			Movement.AddVelocity(HorizontalVelocity);
			VerticalVelocity *= FrictionFactor;
		}

		CustomVelocity += DestinationComp.CustomAcceleration * DeltaTime;
		CustomVelocity *= FrictionFactor;
		Movement.AddVelocity(CustomVelocity);

		// Turn towards focus?
		if (DestinationComp.Focus.IsValid())
			MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, Settings.TurnDuration, DeltaTime, Movement);
		// Turn towards destination if still some ways off
		else if (DestinationComp.HasDestination() && !OwnLoc.IsWithinDist(Destination, PathingSettings.AtDestinationRange))
			MoveComp.RotateTowardsDirection(MoveDir, Settings.TurnDuration, DeltaTime, Movement);
		// Align actor and movecomp up if necessary
		else if (MoveComp.WorldUp.DotProduct(Owner.ActorUpVector) < 0.99)
			MoveComp.RotateTowardsDirection(Owner.ActorForwardVector, Settings.TurnDuration, DeltaTime, Movement);
		// Slow to a stop
		else  
			MoveComp.StopRotating(4.0, DeltaTime, Movement);

		Movement.AddPendingImpulses();
		Movement.AddVelocity(VerticalVelocity);
		Movement.AddGravityAcceleration();
	}

	FVector GetCurrentDestination()
	{
		if (PathingSettings.bIgnorePathfinding)
			return DestinationComp.Destination;

		return PathFollowingComp.GetPathfindingDestination();	
	}

	bool IsMovingToFinalDestination()
	{
		if (PathingSettings.bIgnorePathfinding)
			return true;

		return PathFollowingComp.IsMovingToFinalDestination();
	}
}
