class UGravityBikeFreeGroundMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFree);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFreeMovement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 80;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeMovementComponent MoveComp;
	UGravityBikeFreeMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
        MoveComp = UGravityBikeFreeMovementComponent::Get(GravityBike);
		Movement = MoveComp.SetupMovementData(UGravityBikeFreeMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
#if !RELEASE
		if (DevToggleGravityBikeFree::DisableGravityBikeDriving.IsEnabled()) 
			return false;
#endif

		if(MoveComp.HasMovedThisFrame())
			return false;

		if(MoveComp.IsInAir())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
#if !RELEASE
		if (DevToggleGravityBikeFree::DisableGravityBikeDriving.IsEnabled())
			return true;
#endif

		if(MoveComp.HasMovedThisFrame())
			return true;

		if(MoveComp.IsInAir())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(Movement, GravityBike.GetAcceleratedUp()))
			return;

		if(HasControl())
		{
			float ForwardSpeed = MoveComp.GetForwardSpeed(MoveComp.WorldUp);
			MoveComp.AccelerateTowardsTargetSpeed(ForwardSpeed, DeltaTime);

			FVector Velocity = MoveComp.Velocity;
			MoveComp.SetForwardSpeed(Velocity, ForwardSpeed, MoveComp.WorldUp, DeltaTime, GravityBike.Settings.SideSpeedDeceleration);
			Movement.AddVelocity(Velocity);

			GravityBike.TurnBike(Movement, DeltaTime);

			Movement.AddGravityAcceleration();
			Movement.AddPendingImpulses();
			Movement.ApplyMaximumSpeed(GravityBike.Settings.MaxSpeedLimit);
		}
		else
		{
			Movement.ApplyCrumbSyncedGroundMovement();
		}

		MoveComp.ApplyMove(Movement);
	}
}