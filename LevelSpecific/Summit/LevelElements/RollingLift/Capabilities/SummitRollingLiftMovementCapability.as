class USummitRollingLiftMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	ASummitRollingLift Lift;

	UHazeMovementComponent MoveComp;
	USteppingMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Lift = Cast<ASummitRollingLift>(Owner);

		MoveComp = UHazeMovementComponent::Get(Lift);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(Lift.bIsControlled)
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(Lift.bIsControlled)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector CurrentVelocity = MoveComp.HorizontalVelocity;
				CurrentVelocity -= Lift.GetDeceleration(CurrentVelocity, DeltaTime);
				if(MoveComp.IsOnAnyGround())
					CurrentVelocity += Lift.GetSlopeAcceleration(DeltaTime);
				CurrentVelocity = Lift.ClampVelocityToMaxSpeed(CurrentVelocity);
				Movement.AddHorizontalVelocity(CurrentVelocity);

				Movement.AddGravityAcceleration();
				Movement.AddOwnerVerticalVelocity();
			}
			// Remote update, TODO, implement
			// else
			// {
			// 	if(MoveComp.IsInAir())
			// 		Movement.ApplyCrumbSyncedAirMovement();
			// 	else
			// 		Movement.ApplyCrumbSyncedGroundMovement();
			// }
			MoveComp.ApplyMove(Movement);
		}
	}
};