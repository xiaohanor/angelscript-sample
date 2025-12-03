class UDentistSplitToothGroundIdleMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(Dentist::SplitTooth::SplitToothTag);
	default CapabilityTags.Add(Dentist::Tags::BlockedWhileDash);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 90;

	UDentistSplitToothComponent SplitToothComp;

	UHazeMovementComponent MoveComp;
	UDentistToothMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SplitToothComp = UDentistSplitToothComponent::Get(Owner);

		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupMovementData(UDentistToothMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!SplitToothComp.bIsSplit)
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		if(MoveComp.IsInAir())
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!SplitToothComp.bIsSplit)
			return true;

		if (MoveComp.HasMovedThisFrame())
			return true;

		if(MoveComp.IsInAir())
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
		if (!MoveComp.PrepareMove(Movement))
			return;

		if (HasControl())
		{
			Movement.AddOwnerVerticalVelocity();

			FVector HorizontalVelocity = MoveComp.GetHorizontalVelocity();
			HorizontalVelocity = Math::VInterpConstantTo(HorizontalVelocity, FVector::ZeroVector, DeltaTime, SplitToothComp.Settings.GroundDeceleration);
			Movement.AddHorizontalVelocity(HorizontalVelocity);

			Movement.AddGravityAcceleration();
			Movement.AddPendingImpulses();
		}
		else
		{
			Movement.ApplyCrumbSyncedGroundMovement();
		}

		MoveComp.ApplyMove(Movement);
	}
};