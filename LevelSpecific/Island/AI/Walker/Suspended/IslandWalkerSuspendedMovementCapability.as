class UIslandWalkerSuspendedMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 80;
	
	UBasicAICharacterMovementComponent MoveComp;
	UIslandWalkerPhaseComponent PhaseComp;
	UIslandWalkerComponent WalkerComp;
	UBasicAIDestinationComponent DestinationComp;
	UIslandWalkerSettings Settings;
	UTeleportingMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		DestinationComp = UBasicAIDestinationComponent::Get(Owner);
		PhaseComp = UIslandWalkerPhaseComponent::Get(Owner);
		WalkerComp = UIslandWalkerComponent::Get(Owner);
		Movement = MoveComp.SetupTeleportingMovementData();
		Settings = UIslandWalkerSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (PhaseComp.Phase != EIslandWalkerPhase::Suspended)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;
		if (PhaseComp.Phase != EIslandWalkerPhase::Suspended)
			return true;		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(Movement))
			return;

		if(HasControl())
			ComposeMovement(DeltaTime);
		else
			Movement.ApplyCrumbSyncedAirMovement();			

		MoveComp.ApplyMove(Movement);
		DestinationComp.bHasPerformedMovement = true;
	}

	void ComposeMovement(float DeltaTime)
	{	
		FVector OwnLoc = Owner.ActorLocation;
		FVector Velocity = MoveComp.Velocity;
		FVector Destination = DestinationComp.HasDestination() ? DestinationComp.Destination : WalkerComp.GetSuspendLocation();

		// Accelerate towards destination; we want some oscillation
		if (!Destination.IsWithinDist(OwnLoc, 100.0))
		{
			FVector AccDir = (Destination - OwnLoc).GetSafeNormal();
			float Acc = DestinationComp.HasDestination() ? DestinationComp.Speed : Settings.SuspendAcceleration;
			Movement.AddAcceleration(AccDir * Acc);
		}
		Velocity *= Math::Pow(Math::Exp(-Settings.SuspendFriction), DeltaTime);

		Movement.AddVelocity(Velocity);
		Movement.AddPendingImpulses();

		// No falling, that is done by animations

		// Turn towards focus or come to a stop
		if (DestinationComp.Focus.IsValid())
			MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, Settings.SuspendedTurnDuration, DeltaTime, Movement, true);
		else 
			MoveComp.StopRotating(4.0, DeltaTime, Movement, true);
	}
}