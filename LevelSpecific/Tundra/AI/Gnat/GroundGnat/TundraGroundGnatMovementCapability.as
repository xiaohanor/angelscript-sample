
class UTundraGroundGnatMovementCapability : UHazeCapability
{	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"GroundMovement");	

	default DebugCategory = CapabilityTags::Movement;

	default TickGroup = EHazeTickGroup::ActionMovement;

	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UPathfollowingMoveToComponent PathFollowingComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UBasicAIAnimationComponent AnimComp;
	UBasicAIMovementSettings MoveSettings;
	UPathfollowingSettings PathingSettings;
	UGroundPathfollowingSettings GroundPathfollowingSettings;
	USteppingMovementData Movement;

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
		AnimComp = UBasicAIAnimationComponent::GetOrCreate(Owner);
		MoveSettings = UBasicAIMovementSettings::GetSettings(Owner);
		PathingSettings = UPathfollowingSettings::GetSettings(Owner);
		GroundPathfollowingSettings = UGroundPathfollowingSettings::GetSettings(Owner);
		Movement = MoveComp.SetupSteppingMovementData();
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
		AccUp.SnapTo(Owner.ActorUpVector.Rotation());
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		AccUp.AccelerateTo(FVector::UpVector.Rotation(), 2.0, DeltaTime);
		if(!MoveComp.PrepareMove(Movement, AccUp.Value.Vector()))
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
			PrevLocation = Owner.ActorLocation;
		}

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
