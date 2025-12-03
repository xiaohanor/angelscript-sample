class USkylineGeckoDirectMovementCapability : UHazeCapability
{	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"WallclimbingMovement");	

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 80; 
	default DebugCategory = CapabilityTags::Movement;

	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;

	UWallclimbingComponent WallclimbingComp;
	UWallclimbingPathfollowingSettings WallPathfollowingSettings;
	UPathfollowingSettings PathingSettings;
	USkylineGeckoSettings Settings;
	FHazeAcceleratedRotator AccUp;

	USteppingMovementData Movement;

	FVector PrevLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestinationComp = UBasicAIDestinationComponent::Get(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::Get(Owner); // This has to be created before MoveComp runs BeginPlay
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSteppingMovementData();
		WallclimbingComp = UWallclimbingComponent::Get(Owner);
		WallPathfollowingSettings = UWallclimbingPathfollowingSettings::GetSettings(Owner);
		PathingSettings = UPathfollowingSettings::GetSettings(Owner);
		Settings = USkylineGeckoSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return false;
		if (!PathingSettings.bIgnorePathfinding)
			return false;
	    return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return true;
		if (!PathingSettings.bIgnorePathfinding)
			return true;
        return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		WallclimbingComp.Path.Reset();
		PrevLocation = Owner.ActorLocation;
		AccUp.SnapTo(MoveComp.WorldUp.Rotation());
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(Movement, AccUp.AccelerateTo(GetTargetUp().Rotation(), 1.0, DeltaTime).Vector()))
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

		MoveComp.ApplyMove(Movement);
		DestinationComp.bHasPerformedMovement = true;
	}

	FVector GetTargetUp()
	{
		if (WallclimbingComp.DestinationUpVector.Get().IsZero())
			return MoveComp.WorldUp;
		return WallclimbingComp.DestinationUpVector.Get();	
	}


	void ComposeMovement(float DeltaTime)
	{	
		FVector OwnLoc = Owner.ActorLocation;
		FVector Velocity = MoveComp.Velocity;
		FVector VerticalVelocity = MoveComp.WorldUp * MoveComp.WorldUp.DotProduct(Velocity);
		FVector HorizontalVelocity = Velocity - VerticalVelocity;
		FVector SplineDir = FVector::ZeroVector;

		float AirFrictionFactor = Math::Pow(Math::Exp(-Settings.AirFriction), DeltaTime);
		float GroundFrictionFactor = Math::Pow(Math::Exp(-Settings.GroundFriction), DeltaTime);

		if (!DestinationComp.HasDestination() || OwnLoc.IsWithinDist(DestinationComp.Destination, 80.0))
		{
			// No destination or at destination, slow to a stop
			HorizontalVelocity *= Math::Pow(Math::Exp(-Settings.GroundFriction), DeltaTime);
			DestinationComp.ReportStopping();
		}
		else
		{
			FVector DestDir = (DestinationComp.Destination - OwnLoc).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
			float DestDot = HorizontalVelocity.DotProduct(DestDir);
			FVector DirectionalVelocity = (DestDot > 0.0) ? DestDir * DestDot : FVector::ZeroVector;
			
			// High friction for velocity not towards destination
			FVector LateralVelocity = HorizontalVelocity - DirectionalVelocity;
			LateralVelocity *= GroundFrictionFactor;

			// Accelerate towards destination and apply low friction
			DirectionalVelocity += DestDir * DestinationComp.Speed * Settings.AirFriction * DeltaTime;
			DirectionalVelocity *= AirFrictionFactor;
			HorizontalVelocity = DirectionalVelocity + LateralVelocity;
		}

		// Fall
		VerticalVelocity *= AirFrictionFactor;
		Movement.AddGravityAcceleration();
		
		Movement.AddVelocity(VerticalVelocity + HorizontalVelocity);

		Movement.AddPendingImpulses();

		// Turn towards focus?
		if (DestinationComp.Focus.IsValid())
			MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, Settings.TurnDuration, DeltaTime, Movement, true);
		// Turn in direction of spline when we have a destination
		else if (DestinationComp.HasDestination() && !SplineDir.IsZero())
			MoveComp.RotateTowardsDirection(SplineDir, Settings.TurnDuration, DeltaTime, Movement, true);
		// Always rotate when we're not aligned with gravity
		else if (MoveComp.WorldUp.DotProduct(Owner.ActorUpVector) < 0.99)
			MoveComp.RotateTowardsDirection(Owner.ActorForwardVector, Settings.TurnDuration, DeltaTime, Movement);
		// Slow to a stop if we've nothing better to do
		else 
			MoveComp.StopRotating(5.0, DeltaTime, Movement);
		// TODO: Custom acceleration and Movement.AddPendingImpulses();

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(OwnLoc, DestinationComp.Destination, FLinearColor::Green);
		}
#endif
	}
}

