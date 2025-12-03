class UTundraFishieSwimAlongSplineMovementCapability : UHazeCapability
{	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"SwimmingMovement");	
	default CapabilityTags.Add(n"SplineMovement");	

	default DebugCategory = CapabilityTags::Movement;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 50; // Before regular movement

	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UBasicAIAnimationComponent AnimComp;
	UBasicAIMovementSettings MoveSettings;
	UTeleportingMovementData Movement;
	FVector PrevLocation;
	FHazeAcceleratedRotator AccRot;
	FHazeAcceleratedFloat AccCaptureAlpha;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestinationComp = UBasicAIDestinationComponent::GetOrCreate(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner); // This has to be created before MoveComp runs BeginPlay
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		AnimComp = UBasicAIAnimationComponent::GetOrCreate(Owner);
		MoveSettings = UBasicAIMovementSettings::GetSettings(Owner);
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
		AccRot.SnapTo(Owner.ActorRotation);
		if (HasControl())
		{
			DestinationComp.FollowSplinePosition = DestinationComp.FollowSpline.GetClosestSplinePositionToWorldLocation(Owner.ActorLocation);
			AccCaptureAlpha.SnapTo(0.0);
			if (DestinationComp.FollowSplinePosition.WorldLocation.IsWithinDist(Owner.ActorLocation, 0.1))
				AccCaptureAlpha.SnapTo(1.0);
		}	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DestinationComp.FollowSplinePosition = FSplinePosition();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		AccRot.AccelerateTo(GetCurrentSplineRotation(), 2.0, DeltaTime);
		if(!MoveComp.PrepareMove(Movement, AccRot.Value.UpVector))
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

	FRotator GetCurrentSplineRotation()
	{
		if (HasControl())
		{
			return DestinationComp.FollowSplinePosition.WorldRotation.Rotator();	
		}
		else
		{
			FHazeSyncedActorPosition CrumbPos = MoveComp.GetCrumbSyncedPosition();
			return CrumbPos.WorldRotation;		
		}
	}

	void ComposeMovement(float DeltaTime)
	{	
		FVector Velocity = MoveComp.Velocity;
		AccCaptureAlpha.AccelerateToWithStop(1.0, 5.0, DeltaTime, 1.0);

		// Accelerate along spline
		float Fwd = DestinationComp.bFollowSplineForwards ? 1.0 : -1.0; 
		FVector SplineDir = DestinationComp.FollowSplinePosition.WorldForwardVector;
		Velocity += SplineDir * Fwd * DestinationComp.Speed * DeltaTime;
		Velocity *= Math::Pow(Math::Exp(-MoveSettings.AirFriction), DeltaTime);

		// Move along spline
		float SplineSpeed = SplineDir.DotProduct(Velocity);
		float Delta = SplineSpeed * DeltaTime;
		Delta += DestinationComp.Speed * 0.5 * Math::Square(DeltaTime);
		DestinationComp.FollowSplinePosition.Move(Delta);
		FVector NewLoc = Math::Lerp(Owner.ActorLocation + Velocity * DeltaTime, DestinationComp.FollowSplinePosition.WorldLocation, AccCaptureAlpha.Value);
		Movement.AddDeltaFromMoveToPositionWithCustomVelocity(NewLoc, Velocity);

		// Turn towards focus or direction of spline
		if (DestinationComp.Focus.IsValid())
			MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, MoveSettings.TurnDuration, DeltaTime, Movement);
		else 
			MoveComp.RotateTowardsDirection(DestinationComp.FollowSplinePosition.WorldForwardVector * Fwd, MoveSettings.TurnDuration, DeltaTime, Movement);

		Movement.AddPendingImpulses();
	}
}
