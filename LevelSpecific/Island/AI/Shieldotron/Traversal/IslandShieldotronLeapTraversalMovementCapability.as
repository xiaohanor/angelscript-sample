
class UIslandShieldotronLeapTraversalMovementCapability : UBasicAIMovementCapability
{	
	default CapabilityTags.Add(n"Leap");	
	default CapabilityTags.Add(n"TraversalMovement");	

	UTrajectoryTraversalComponent TraversalComp;
	UIslandShieldotronJumpComponent JumpComp;
	UBasicAITraversalSettings TraversalSettings; 
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 80;

	AAIIslandShieldotron ShieldotronOwner;

	FTraversalTrajectory TraversalTrajectory;
	FVector TrajectoryLocation;
	float TraversedDuration;
	float TrajectoryDuration = BIG_NUMBER;
	float LandAnticipationLength = 0.23;
	UTeleportingMovementData TeleportingMovement;
	bool bHasCrumbedLanding = false;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		TraversalComp = UTrajectoryTraversalComponent::Get(Owner);
		JumpComp = UIslandShieldotronJumpComponent::Get(Owner);
		TraversalSettings = UBasicAITraversalSettings::GetSettings(Owner);
		TeleportingMovement = Cast<UTeleportingMovementData>(Movement);
		ShieldotronOwner = Cast<AAIIslandShieldotron>(Owner);
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		if (RespawnComp != nullptr)
		 	RespawnComp.OnRespawn.AddUFunction(TraversalComp, n"OnReset");
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
		UIslandShieldotronEffectHandler::Trigger_OnJumpStart(Owner, FIslandShieldotronJumpBoostParams(ShieldotronOwner.JumpBoostVFX));
		TraversalTrajectory = FTraversalTrajectory();
		bHasCrumbedLanding = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(CapabilityTags::Movement, this);
		UIslandShieldotronEffectHandler::Trigger_OnJumpStop(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UpdateTraversal();

		Super::TickActive(DeltaTime);

		if (TraversedDuration >= TrajectoryDuration)
		{
		 	TraversalComp.ReachDestination(TraversalTrajectory.LandLocation);
		}
		else if (TraversedDuration >= TrajectoryDuration - LandAnticipationLength && !bHasCrumbedLanding)
		{
			if (HasControl())
				CrumbRequestLandAnimation();
			bHasCrumbedLanding = true;
		}
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

		if (TraversedDuration >= TrajectoryDuration)
			TraversedDuration = TrajectoryDuration;
		
		FVector NewTrajectoryLocation = TraversalTrajectory.GetLocation(TraversedDuration);
		FVector DeltaAlongTrajectory = NewTrajectoryLocation - TrajectoryLocation;

		//TraversalTrajectory.DrawDebug(FLinearColor::Green, 0.1);

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

	UFUNCTION(CrumbFunction)
	void CrumbRequestLandAnimation()
	{
		AnimComp.RequestFeature(FeatureTagIslandSecurityMech::Land, EBasicBehaviourPriority::High, Owner); // cleared in land behaviour.
	}
}
