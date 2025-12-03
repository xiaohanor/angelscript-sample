class UIslandPunchotronSplineMovementCapability : UHazeCapability
{	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"SplineMovement");	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 60;

	default DebugCategory = CapabilityTags::Movement;

	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UBasicAITargetingComponent TargetComp;

	bool bCapturedSpline = false;
	USimpleMovementData Movement;


  	FVector CustomVelocity;
	FVector PrevLocation;

	UIslandPunchotronSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestinationComp = UBasicAIDestinationComponent::GetOrCreate(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner, n"SyncedPosition"); // This has to be created before MoveComp runs BeginPlay
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		TargetComp = UBasicAITargetingComponent::GetOrCreate(Owner);
		Settings = UIslandPunchotronSettings::GetSettings(Owner);
		Movement = MoveComp.SetupSimpleMovementData();
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
		// OnActivated only needs to run on control side. Movement is replicated by crumb synced actor position, CrumbMotionComp.
		if (!HasControl())
			return;

		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		PrevLocation = Owner.ActorLocation;
		
		bCapturedSpline = false;
		FVector SplinePointActorWorldLocation = DestinationComp.FollowSpline.GetOwner().ActorLocation;

		// Set spline move direction
		FVector OwnerToSplinePoint = (SplinePointActorWorldLocation - Owner.ActorLocation).GetSafeNormal2D(); // Assumes the SplinePointActor's location is in the center of looping spline.		
		FVector CounterClockwiseDirection = FVector::UpVector.CrossProduct(OwnerToSplinePoint).GetSafeNormal2D(); // CCW is the forward direction when circle is created with spline tool
		FVector OwnerToTarget = (TargetComp.Target.ActorLocation - Owner.ActorLocation).GetSafeNormal2D();	

		FVector SplinePointToOwner = OwnerToSplinePoint * -1.0;
		FVector DesiredLocation;

		if (CounterClockwiseDirection.DotProduct(OwnerToTarget) > 0) // CCW direction
		{
			DestinationComp.bFollowSplineForwards = true;
			FVector OrthogonalDirLeft = SplinePointToOwner.CrossProduct(FVector::UpVector).GetSafeNormal2D();
			FVector DesiredDir = OrthogonalDirLeft.RotateTowards(SplinePointToOwner, 45);
			DesiredLocation = SplinePointActorWorldLocation + DesiredDir * DestinationComp.FollowSpline.BoundsRadius;
		}
		else // Clockwise direction
		{			
			DestinationComp.bFollowSplineForwards = false;
			FVector OrthogonalDirRight = FVector::UpVector.CrossProduct(SplinePointToOwner).GetSafeNormal2D();
			FVector DesiredDir = OrthogonalDirRight.RotateTowards(SplinePointToOwner, 45);
			DesiredLocation = SplinePointActorWorldLocation + DesiredDir * DestinationComp.FollowSpline.BoundsRadius;
		}		
		
		float DistanceAlongSpline = DestinationComp.FollowSpline.GetClosestSplineDistanceToWorldLocation(DesiredLocation);
		DestinationComp.FollowSplinePosition = FSplinePosition(DestinationComp.FollowSpline, DistanceAlongSpline, DestinationComp.bFollowSplineForwards);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DestinationComp.FollowSplinePosition = FSplinePosition();
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
			Movement.ApplyCrumbSyncedGroundMovementWithCustomVelocity(Velocity);
			PrevLocation = Owner.ActorLocation;
		}

		MoveComp.ApplyMove(Movement);
		DestinationComp.bHasPerformedMovement = true;
	}

	void ComposeMovement(float DeltaTime)
	{	
		FVector OwnLoc = Owner.ActorLocation;
		FVector Velocity = MoveComp.Velocity - CustomVelocity;
		FVector MoveDir = Owner.ActorForwardVector;

		// Move to spline, then follow along that spline
		if (!bCapturedSpline && Owner.ActorLocation.IsWithinDist(DestinationComp.FollowSplinePosition.WorldLocation, Settings.SplineFollowCaptureDistance))
			CaptureSpline();

		const float FrictionFactor = Math::Pow(Math::Exp(-Settings.SplineGroundFriction), DeltaTime);
		
		if (!bCapturedSpline)
		{
			// Move to spline
			// TODO: enter at a tangent
			MoveDir = (DestinationComp.FollowSplinePosition.WorldLocation - OwnLoc).GetSafeNormal();
			Velocity += MoveDir * DestinationComp.Speed * DeltaTime;				
			Velocity *= FrictionFactor;
			Movement.AddVelocity(Velocity);
		}
		else
		{
			// Accelerate along spline
			FVector SplineDir = DestinationComp.FollowSplinePosition.WorldForwardVector;
			Velocity += SplineDir * DestinationComp.Speed * DeltaTime;
			Velocity *= FrictionFactor;

			// Move along spline
			FVector PrevLocAlongSpline = DestinationComp.FollowSplinePosition.WorldLocation;
			float SplineSpeed = SplineDir.DotProduct(Velocity);
			DestinationComp.FollowSplinePosition.Move(SplineSpeed * DeltaTime);
			Movement.AddDelta(DestinationComp.FollowSplinePosition.WorldLocation - PrevLocAlongSpline);
			
			// Adjust spline-orthogonal velocity
			FVector OrthogonalVelocity = Velocity.ConstrainToPlane(SplineDir);
			OrthogonalVelocity *= Math::Pow(Math::Exp(- Settings.SplineCaptureBrakeFriction), DeltaTime);
			Movement.AddVelocity(OrthogonalVelocity);
			MoveDir = SplineDir; // TODO: factor in orthogonal velocity!
		}
		
		CustomVelocity += DestinationComp.CustomAcceleration * DeltaTime;
		CustomVelocity *= FrictionFactor;
		Movement.AddVelocity(CustomVelocity);

		// Turn towards focus or direction of spline
		if (DestinationComp.Focus.IsValid())
			MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, Settings.TurnDuration, DeltaTime, Movement);
		else 
			MoveComp.RotateTowardsDirection(MoveDir, Settings.TurnDuration, DeltaTime, Movement);

		Movement.AddPendingImpulses();
	}

	void CaptureSpline()
	{
		bCapturedSpline = true;		
	}
}