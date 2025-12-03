class UIslandWalkerGroundMovementCapability : UHazeCapability
{	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default DebugCategory = CapabilityTags::Movement;

	UBasicAIDestinationComponent DestinationComp;
	UBasicAICharacterMovementComponent MoveComp;
	UIslandWalkerPhaseComponent PhaseComp;
	UIslandWalkerComponent WalkerComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UIslandWalkerSettings Settings;
	UTeleportingMovementData Movement;

	FVector PrevLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestinationComp = UBasicAIDestinationComponent::Get(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner); // This has to be created before MoveComp runs BeginPlay
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		PhaseComp = UIslandWalkerPhaseComponent::Get(Owner);
		WalkerComp = UIslandWalkerComponent::Get(Owner);
		Settings = UIslandWalkerSettings::GetSettings(Owner);
		Movement = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return false;
		if (PhaseComp.Phase != EIslandWalkerPhase::Walking)
			return false;
        return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return true;
		if (PhaseComp.Phase != EIslandWalkerPhase::Walking)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		PrevLocation = Owner.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
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
		// TODO: Root motion based movement and rotation

		FVector Velocity = MoveComp.Velocity;
		FVector VerticalVelocity = Velocity.ConstrainToDirection(Owner.ActorUpVector);
		FVector HorizontalVelocity = Velocity - VerticalVelocity;
		if (DestinationComp.HasDestination())
		{
			// Horizontal linear movement only for now
			FVector ToDest = (DestinationComp.Destination - Owner.ActorLocation).GetSafeNormal2D();
			HorizontalVelocity = ToDest * DestinationComp.Speed * DeltaTime; 
		}
		else
		{
			// Slide to a stop quickly
			HorizontalVelocity *= Math::Pow(Math::Exp(-10.0), DeltaTime);
		}

		// Fall down to arena
		if (Owner.ActorLocation.Z > WalkerComp.ArenaLimits.Height - 12.0)
		{
			Movement.AddGravityAcceleration();
		}
		else
		{
			if (VerticalVelocity.Z < 0.0)
				VerticalVelocity.Z = 0.0;
			if (Owner.ActorLocation.Z < WalkerComp.ArenaLimits.Height - 20.0)
				VerticalVelocity.Z = 20.0;
		}

		Movement.AddVelocity(HorizontalVelocity + VerticalVelocity);

		Movement.AddPendingImpulses();

		// Allow some nudging of rotation
		if (DestinationComp.Focus.IsValid())
		  	MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, Settings.TurnDuration, DeltaTime, Movement);
		else  
			MoveComp.StopRotating(10.0, DeltaTime, Movement);

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
		}
#endif
	}
}
