class USkylineHighwayDraggableCoverMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"WhipDrag");
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Movement;

	USkylineHighwayDraggableCoverComponent DraggableComp;
	UGravityWhipResponseComponent WhipResponseComp;
	UHazeMovementComponent MoveComp;
	USimpleMovementData Movement;
	FVector PrevLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DraggableComp = USkylineHighwayDraggableCoverComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
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
			Movement.ApplyCrumbSyncedAirMovementWithCustomVelocity(Velocity);
			PrevLocation = Owner.ActorLocation;
		}

		MoveComp.ApplyMove(Movement);
	}

	void ComposeMovement(float DeltaTime)
	{
		const float Friction = 1;
		FVector HorizontalVelocity = MoveComp.HorizontalVelocity;

		if(DraggableComp.bHasTargetLocation)
		{
			if(!Owner.ActorLocation.IsWithinDist2D(DraggableComp.TargetLocation, 50))
			{
				FVector Dir = (DraggableComp.TargetLocation - Owner.ActorLocation).GetSafeNormal();
				Dir.Z = 0;
				Movement.AddAcceleration(Dir * DraggableComp.MoveSpeed);
			}
		}
		
		Movement.AddAcceleration(-HorizontalVelocity * Friction);
		Movement.AddVelocity(HorizontalVelocity);
	}
}