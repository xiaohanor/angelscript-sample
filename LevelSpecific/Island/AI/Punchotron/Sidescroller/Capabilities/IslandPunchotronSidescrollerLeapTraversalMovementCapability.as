
class UIslandSidescrollerPunchotronLeapTraversalMovementCapability : UBasicAIMovementCapability
{	
	default CapabilityTags.Add(n"Leap");	
	default CapabilityTags.Add(n"TraversalMovement");	

	UTrajectoryTraversalComponent TraversalComp;
	UIslandPunchotronSidescrollerLandingComponent LandingComp;
	AAIIslandPunchotronSidescroller Punchotron;
	UBasicAITraversalSettings TraversalSettings; 
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 80;

	FTraversalTrajectory TraversalTrajectory;
	FVector TrajectoryLocation;
	float TraversedDuration;
	float TrajectoryDuration = BIG_NUMBER;	
	UTeleportingMovementData TeleportingMovement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		TraversalComp = UTrajectoryTraversalComponent::Get(Owner);
		LandingComp = UIslandPunchotronSidescrollerLandingComponent::Get(Owner);
		TraversalSettings = UBasicAITraversalSettings::GetSettings(Owner);
		TeleportingMovement = Cast<UTeleportingMovementData>(Movement);
		Punchotron = Cast<AAIIslandPunchotronSidescroller>(Owner);
	}

	UBaseMovementData SetupMovementData() override
	{
		return MoveComp.SetupTeleportingMovementData();
	} 

	bool PrepareMove() override
	{
		return MoveComp.PrepareMove(TeleportingMovement);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TraversalComp.HasDestination())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TraversalComp.HasDestination())
			return true; 
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Owner.BlockCapabilitiesExcluding(CapabilityTags::Movement, n"TraversalMovement", this);
		TraversalTrajectory = FTraversalTrajectory();
		Punchotron.AddMovementIgnoreOneWayPlatforms(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(CapabilityTags::Movement, this);
		if (LandingComp.CanTriggerLandingEffect())
		{
			UIslandPunchotronEffectHandler::Trigger_OnLanded(Owner, FIslandPunchotronOnLandedParams(0.25));
			LandingComp.UpdateLandingTimestamp();
		}
		Punchotron.ClearMovementIgnoreOneWayPlatforms(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UpdateTraversal();

		Super::TickActive(DeltaTime);

		if (TraversedDuration >= TrajectoryDuration)
		 	TraversalComp.ReachDestination(TraversalTrajectory.LandLocation);
	}

	void UpdateTraversal()
	{
		if (!HasControl())
			return; // No need to set up update, this is only used on control side

		FTraversalTrajectory PrevTrajectory = TraversalTrajectory;

		// Consume traversing point
		TraversalComp.ConsumeDestination(TraversalTrajectory);
		if (PrevTrajectory != TraversalTrajectory)
		{
			// Start new traversal
			TraversedDuration = 0.0;
			TrajectoryDuration = TraversalTrajectory.GetTotalTime();
			TrajectoryLocation = TraversalTrajectory.GetLocation(0.0);
		}
	}

	void ComposeMovement(float DeltaTime) override
	{	
		if (TrajectoryDuration == 0.0)
			return;

		TraversedDuration += DeltaTime;
		TraversedDuration = Math::Min(TraversedDuration, TrajectoryDuration); // Clamp duration

		FVector NewTrajectoryLocation = TraversalTrajectory.GetLocation(TraversedDuration);
		FVector DeltaAlongTrajectory = NewTrajectoryLocation - TrajectoryLocation;

		FVector Delta = DeltaAlongTrajectory; 

		Movement.AddDelta(Delta);

		// Turn towards focus or in direction of Trajectory
		if (DestinationComp.Focus.IsValid())
		 	MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, TraversalSettings.TurnDuration, DeltaTime, Movement);
		else 
			MoveComp.RotateTowardsDirection(TraversalTrajectory.LaunchVelocity, TraversalSettings.TurnDuration, DeltaTime, Movement);

		Movement.AddPendingImpulses();

		TrajectoryLocation = NewTrajectoryLocation;
	}
}
