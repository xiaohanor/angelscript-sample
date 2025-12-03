class USummitKnightMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default DebugCategory = CapabilityTags::Movement;

	UBasicAIDestinationComponent DestinationComp;
	UBasicAICharacterMovementComponent MoveComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	USummitKnightComponent KnightComp;
	UTeleportingMovementData Movement;
	USummitKnightSettings Settings;
	FVector PrevLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestinationComp = UBasicAIDestinationComponent::GetOrCreate(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner); // This has to be created before MoveComp runs BeginPlay
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		KnightComp = USummitKnightComponent::Get(Owner);
		Settings = USummitKnightSettings::GetSettings(Owner);
		Movement = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// This really should be here and as a ShouldDeactivate condition, but we will early out in TickActive so works. Bit late to poke at this...
		// if (DestinationComp.bHasPerformedMovement)
		// 	return false;
        return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		PrevLocation = Owner.ActorLocation;

		// Knight is attached in level (to make moving the fightin editor easier?), set her free!
		Owner.DetachRootComponentFromParent();
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
			Movement.ApplyCrumbSyncedAirMovementWithCustomVelocity(Velocity);;
			PrevLocation = Owner.ActorLocation;
		}

		MoveComp.ApplyMove(Movement);
		DestinationComp.bHasPerformedMovement = true;
	}

	void ComposeMovement(float DeltaTime)
	{
		FVector Velocity = MoveComp.HorizontalVelocity;
		if (DestinationComp.HasDestination())
			Movement.AddAcceleration((DestinationComp.Destination - Owner.ActorLocation).GetSafeNormal2D() * DestinationComp.Speed * Settings.Friction); 
		Velocity *= Math::Pow(Math::Exp(-Settings.Friction), DeltaTime);
		Movement.AddVelocity(Velocity);

		if ((KnightComp.Arena != nullptr) && (Owner.ActorLocation.Z > KnightComp.Arena.Center.Z))
		{
			// Always fall down to arena
			Movement.AddOwnerVerticalVelocity();
			Movement.AddGravityAcceleration();
		}

		if (DestinationComp.Focus.IsValid())
		{
			// Look at focus	
			FVector Direction = (DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation);
			Direction.Z = 0.0;
			MoveComp.RotateTowardsDirection(Direction, Settings.RotationDuration, DeltaTime, Movement);
		}
		else  
		{
			MoveComp.StopRotating(5.0, DeltaTime, Movement);
		}
	}
}
