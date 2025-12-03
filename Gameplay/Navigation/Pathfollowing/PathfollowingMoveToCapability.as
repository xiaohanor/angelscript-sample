
class UCharacterPathfollowingMoveToCapability : UHazeCapability
{	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"Pathfinding");
	
	default DebugCategory = CapabilityTags::Movement;

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	UHazeMovementComponent MoveComp;
	UHazeCharacterSkeletalMeshComponent CharacterMesh;
	USteppingMovementData Movement;
	UPathfollowingMoveToComponent MoveToComp;
	UPathfollowingSettings Settings;
	UGroundPathfollowingSettings GroundSettings;
	UBasicAIMovementSettings MoveSettings;
	FHazeAcceleratedRotator AccRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSteppingMovementData();
		CharacterMesh = UHazeCharacterSkeletalMeshComponent::Get(Owner);
		MoveToComp = UPathfollowingMoveToComponent::GetOrCreate(Owner);
		Settings = UPathfollowingSettings::GetSettings(Owner);
		GroundSettings = UGroundPathfollowingSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
        if (!MoveToComp.HasDestination())
			return false;	

        return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
        if (!MoveToComp.HasDestination())
			return true;	

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccRotation.SnapTo(Owner.ActorRotation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(!MoveComp.PrepareMove(Movement))
			return;

		if(HasControl())
		{
			FVector OwnLoc = Owner.ActorLocation;
			FVector Velocity = MoveComp.Velocity;
			float MoveSpeed = 400.0; // TODO: This should be read from settings or some component

			FVector Destination = MoveToComp.GetPathfindingDestination();
			FVector HorizontalVelocity = Velocity.ConstrainToPlane(MoveComp.WorldUp);
			FVector VerticalVelocity = Velocity - HorizontalVelocity;

			FVector MoveDir = (Destination - OwnLoc).GetSafeNormal();
			if (MoveToComp.IsMovingToFinalDestination() && OwnLoc.IsWithinDist(Destination, Settings.AtDestinationRange))
			{
				// Slow to a stop
				FHazeAcceleratedVector AccLocation;
				AccLocation.SnapTo(OwnLoc, HorizontalVelocity);
				AccLocation.AccelerateTo(Destination, 1.0, DeltaTime);
				
				// Keep applying slowed down velocity until we're moving away from destination (this can be handled better, but will at least stop overshoot sliding on slopes)
				if (MoveDir.DotProduct(HorizontalVelocity) > 0.0) 
					Movement.AddHorizontalVelocity(HorizontalVelocity);

				// MoveTo is completed (note that this will usually mean this capability will deactivate)
				MoveToComp.ReportComplete(true);
			}
			else
			{
				// Move towards destination
				FHazeAcceleratedVector AccLocation;
				AccLocation.SnapTo(FVector::ZeroVector, HorizontalVelocity);
				AccLocation.AccelerateTo(MoveDir * MoveSpeed, GroundSettings.AccelerationDuration, DeltaTime);
				Movement.AddVelocity(AccLocation.Velocity);
			}

			// Turn
			AccRotation.Value = Owner.ActorRotation; // In case we get rotated by something else
			if (!OwnLoc.IsWithinDist(Destination, Settings.AtDestinationRange))
			{
				AccRotation.AccelerateTo(MoveDir.Rotation(), MoveSettings.TurnDuration, DeltaTime);				
			}
			else
			{
				AccRotation.Velocity -= AccRotation.Velocity * MoveSettings.StopTurningDamping * DeltaTime;
				AccRotation.Value += AccRotation.Velocity * DeltaTime;
			}
			Movement.SetRotation(AccRotation.Value);

			Movement.AddVelocity(VerticalVelocity);
			Movement.AddGravityAcceleration();
		}
		else // Remote
		{
			Movement.ApplyCrumbSyncedGroundMovement();
		}

		MoveComp.ApplyMove(Movement);

		// Can we request an animtion
		if(CharacterMesh != nullptr && CharacterMesh.CanRequestLocomotion())
		{
			CharacterMesh.RequestLocomotion(n"Movement", this);
		}	
	}	
}
