
UCLASS(Abstract)
class UBasicAIMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	default DebugCategory = CapabilityTags::Movement;

	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UPathfollowingMoveToComponent PathFollowingComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UBasicAIAnimationComponent AnimComp;
	UPathfollowingSettings PathingSettings;
	UBasicAIMovementSettings MoveSettings;
	UBaseMovementData Movement;

    FVector CustomVelocity;
	FVector PrevLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestinationComp = UBasicAIDestinationComponent::GetOrCreate(Owner);
		PathFollowingComp = UPathfollowingMoveToComponent::GetOrCreate(Owner);
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner, n"SyncedMovementPosition"); // This has to be created before MoveComp runs BeginPlay
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		AnimComp = UBasicAIAnimationComponent::GetOrCreate(Owner);
		PathingSettings = UPathfollowingSettings::GetSettings(Owner);
		MoveSettings = UBasicAIMovementSettings::GetSettings(Owner);
		Movement = SetupMovementData();
	}

	UBaseMovementData SetupMovementData()
	{
		return MoveComp.SetupSteppingMovementData();
	} 

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return false;
        return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DestinationComp.bHasPerformedMovement)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		PrevLocation = Owner.ActorLocation;
	}

	bool PrepareMove()
	{
		check(false, "PrepareMove needs to be overridden with appropriate prepares for stepping/sliding/etc movement data!");
		return MoveComp.PrepareMove(Movement);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(!PrepareMove())
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
			ApplyCrumbSyncedMovement(Velocity);
			PrevLocation = Owner.ActorLocation;
		}

		MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimComp.FeatureTag);
		DestinationComp.bHasPerformedMovement = true;
	}

	void ApplyCrumbSyncedMovement(FVector Velocity)
	{
		Movement.ApplyCrumbSyncedAirMovementWithCustomVelocity(Velocity);			
	}

	void ComposeMovement(float DeltaTime)
	{
		// Implement movement in subclasses
	}

	FVector GetCurrentDestination()
	{
		if (PathingSettings.bIgnorePathfinding)
			return DestinationComp.Destination;

		return PathFollowingComp.GetPathfindingDestination();	
	}

	bool IsMovingToFinalDestination()
	{
		if (PathingSettings.bIgnorePathfinding)
			return true;

		return PathFollowingComp.IsMovingToFinalDestination();
	}
}

