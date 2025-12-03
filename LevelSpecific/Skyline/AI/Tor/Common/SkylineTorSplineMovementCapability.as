class USkylineTorSplineMovementCapability : UHazeCapability
{	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"SplineMovement");	

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 90; 
	default DebugCategory = CapabilityTags::Movement;

	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	USkylineTorHoverComponent HoverComp;
	UBasicAIAnimationComponent AnimComp;

	USkylineTorSettings Settings;
	FHazeAcceleratedFloat AccHover;
	UPathfollowingSettings PathingSettings;
	USteppingMovementData Movement;
	FVector PrevLocation;
	FHazeAcceleratedFloat Speed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestinationComp = UBasicAIDestinationComponent::Get(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::Get(Owner); // This has to be created before MoveComp runs BeginPlay
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		HoverComp = USkylineTorHoverComponent::GetOrCreate(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		Movement = MoveComp.SetupSteppingMovementData();
		PathingSettings = UPathfollowingSettings::GetSettings(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return false;
		if (DestinationComp.FollowSpline == nullptr)
			return false;
	    return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return true;
		if (DestinationComp.FollowSpline == nullptr)
			return true;
        return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		PrevLocation = Owner.ActorLocation;

		if (HasControl())
		{
			// DestinationComp.FollowSpline might not be set on remote side, but we only use this data on control side anyway
			DestinationComp.FollowSplinePosition = DestinationComp.FollowSpline.GetClosestSplinePositionToWorldLocation(Owner.ActorLocation);
			Speed.SnapTo(DestinationComp.FollowSplinePosition.WorldForwardVector.DotProduct(MoveComp.Velocity));
		}
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AccHover.SnapTo(0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(Movement))
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
			Movement.ApplyCrumbSyncedAirMovementWithCustomVelocity(Velocity);
			PrevLocation = Owner.ActorLocation;
		}

		MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimComp.FeatureTag);
		DestinationComp.bHasPerformedMovement = true;
	}

	void ComposeMovement(float DeltaTime)
	{	
		if (DeltaTime < SMALL_NUMBER)
			return;

		float DirSign = (DestinationComp.bFollowSplineForwards ? 1.0 : -1.0);
		if (DestinationComp.Speed > 1.0)
			Speed.AccelerateTo(DestinationComp.Speed * DirSign, 2.0, DeltaTime); // Accelerate
		else
			Speed.AccelerateTo(0.0, 0.5, DeltaTime); // Quick brake
	
		DestinationComp.FollowSplinePosition.Move(Speed.Value * DeltaTime);
		FVector Destination = DestinationComp.FollowSplinePosition.WorldLocation; // - DestinationComp.FollowSplinePosition.WorldRightVector * 500;
		Destination.Z = Owner.ActorLocation.Z;

		if(HoverComp != nullptr && HoverComp.bHover)
		{
			AccHover.AccelerateTo(Settings.HoverHeight, 2, DeltaTime);
			Destination.Z = DestinationComp.FollowSplinePosition.WorldLocation.Z + AccHover.Value + Math::Sin(ActiveDuration * 3) * 25;
		}
		else
		{
			AccHover.SnapTo(0);
			Movement.AddOwnerVerticalVelocity();
			Movement.AddGravityAcceleration();
		}

		Movement.AddDeltaFromMoveToPositionWithCustomVelocity(Destination, (DestinationComp.FollowSplinePosition.WorldLocation - Owner.ActorLocation) / DeltaTime);

		// Turn towards focus?
		if (DestinationComp.Focus.IsValid())
			MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, 2, DeltaTime, Movement);		
		// Follow spline direction
		else if (DestinationComp.Speed > 1.0)
			MoveComp.RotateTowardsDirection(DestinationComp.FollowSplinePosition.WorldForwardVector * DirSign, 2.0, DeltaTime, Movement, true);
	}

	private float ArenaHeight(FVector OwnerLocation)
	{
		FVector HoverLoc = OwnerLocation;

		if(DestinationComp.HasDestination())
			HoverLoc = DestinationComp.Destination;

		FVector MeshLocation;
		if(!Pathfinding::FindNavmeshLocation(HoverLoc, 100, Settings.HoverHeight, MeshLocation))
			return Math::Max(OwnerLocation.Z - Settings.HoverHeight, Math::Min(Game::Mio.ActorLocation.Z, Game::Zoe.ActorLocation.Z)); // TODO: Should use an actor in the arena to determine it's height, rather than players

		return MeshLocation.Z;
	}
}

