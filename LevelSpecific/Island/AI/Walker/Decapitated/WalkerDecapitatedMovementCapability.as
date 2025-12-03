// Deprecated, return to use if we want to be able to see walker body at bottom of pool
class UIslandWalkerDecapitatedMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 80;
	
	UBasicAICharacterMovementComponent MoveComp;
	UIslandWalkerPhaseComponent PhaseComp;
	UBasicAIDestinationComponent DestinationComp;
	AIslandWalkerArenaLimits Arena;
	UIslandWalkerSettings Settings;
	UTeleportingMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		PhaseComp = UIslandWalkerPhaseComponent::Get(Owner);
		DestinationComp = UBasicAIDestinationComponent::Get(Owner);
		Movement = MoveComp.SetupTeleportingMovementData();
		Settings = UIslandWalkerSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		if ((PhaseComp.Phase != EIslandWalkerPhase::Decapitated) && (PhaseComp.Phase != EIslandWalkerPhase::Destroyed))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;
		if ((PhaseComp.Phase != EIslandWalkerPhase::Decapitated) && (PhaseComp.Phase != EIslandWalkerPhase::Destroyed))
			return true;		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Arena = UIslandWalkerComponent::Get(Owner).ArenaLimits;
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
		FVector Destination = DestinationComp.Destination;

		// Sink to the bottom of the pool
		if (OwnLoc.Z > Arena.PoolSurfaceHeight)
		{
			Movement.AddGravityAcceleration();
			Velocity *= Math::Pow(Math::Exp(-Settings.SuspendFriction), DeltaTime);
			Movement.AddVelocity(Velocity);
		}

		Movement.AddPendingImpulses();

		// Stop turning
		MoveComp.StopRotating(2.0, DeltaTime, Movement, true);
	}
}