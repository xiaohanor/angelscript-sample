
// Move along spline while changing movement up vector to match spline up.
// Note that users of this need to handle having a weird movement up when spline movement is done.
class UBasicAIClimbAlongSplineMovementCapability : UHazeCapability
{	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"WallclimbingMovement");	
	default CapabilityTags.Add(n"SplineMovement");	

	default DebugCategory = CapabilityTags::Movement;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 50; // Before regular movement

	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UBasicAIAnimationComponent AnimComp;
	UBasicAIMovementSettings MoveSettings;
	UPathfollowingSettings PathingSettings;
	UTeleportingMovementData Movement;

	FVector CustomVelocity;
	FVector PrevLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestinationComp = UBasicAIDestinationComponent::GetOrCreate(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner); // This has to be created before MoveComp runs BeginPlay
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		AnimComp = UBasicAIAnimationComponent::GetOrCreate(Owner);
		MoveSettings = UBasicAIMovementSettings::GetSettings(Owner);
		PathingSettings = UPathfollowingSettings::GetSettings(Owner);
		Movement = MoveComp.SetupTeleportingMovementData();
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
		
		// Assume we start at beginning of spline for now. 
		// Note that this is only used on control side, so we need not replicate followspline
		if (HasControl())
			DestinationComp.FollowSplinePosition = FSplinePosition(DestinationComp.FollowSpline, 0.0, DestinationComp.bFollowSplineForwards);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DestinationComp.FollowSplinePosition = FSplinePosition();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(!MoveComp.PrepareMove(Movement, GetCurrentUpVector()))
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

	FVector GetCurrentUpVector()
	{
		if (HasControl())
		{
			return DestinationComp.FollowSplinePosition.WorldUpVector;	
		}
		else
		{
			FHazeSyncedActorPosition CrumbPos = MoveComp.GetCrumbSyncedPosition();
			return CrumbPos.WorldRotation.UpVector;		
		}
	}

	void ComposeMovement(float DeltaTime)
	{	
		FVector MoveDir = Owner.ActorForwardVector;
		FVector Velocity = MoveComp.Velocity - CustomVelocity;

		// Accelerate along spline
		FVector SplineDir = DestinationComp.FollowSplinePosition.WorldForwardVector;
		Velocity += SplineDir * DestinationComp.Speed * DeltaTime;
		Velocity -= Velocity * MoveSettings.AirFriction * DeltaTime;

		// Move along spline
		FVector PrevLocAlongSpline = DestinationComp.FollowSplinePosition.WorldLocation;
		float SplineSpeed = SplineDir.DotProduct(Velocity);
		DestinationComp.FollowSplinePosition.Move(SplineSpeed * DeltaTime);
		Movement.AddDelta(DestinationComp.FollowSplinePosition.WorldLocation - PrevLocAlongSpline);

		// Adjust spline-orthogonal velocity
		FVector OrthogonalVelocity = Velocity.ConstrainToPlane(SplineDir);
		OrthogonalVelocity -= OrthogonalVelocity * MoveSettings.SplineCaptureBrakeFriction * DeltaTime;
		Movement.AddVelocity(OrthogonalVelocity);
		MoveDir = SplineDir; // TODO: factor in orthogonal velocity!
		
		CustomVelocity += DestinationComp.CustomAcceleration * DeltaTime;
		CustomVelocity -= CustomVelocity * MoveSettings.AirFriction * DeltaTime;
		Movement.AddVelocity(CustomVelocity);

		// Turn towards focus or direction of spline
		if (DestinationComp.Focus.IsValid())
			MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, MoveSettings.TurnDuration, DeltaTime, Movement);
		else 
			MoveComp.RotateTowardsDirection(MoveDir, MoveSettings.TurnDuration, DeltaTime, Movement);

		Movement.AddPendingImpulses();
	}
}
