class UDentistSplitToothAirMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(Dentist::SplitTooth::SplitToothTag);
	default CapabilityTags.Add(Dentist::Tags::BlockedWhileDash);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

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

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!SplitToothComp.bIsSplit)
			return true;

		if (MoveComp.HasMovedThisFrame())
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

			const FVector Input = MoveComp.MovementInput;
			const FVector TargetHorizontalVelocity = Input * SplitToothComp.Settings.AirMaxSpeed;
			HorizontalVelocity = Math::VInterpConstantTo(HorizontalVelocity, TargetHorizontalVelocity, DeltaTime, SplitToothComp.Settings.AirAcceleration);
			Movement.AddHorizontalVelocity(HorizontalVelocity);

			Movement.AddGravityAcceleration();

			if(!HorizontalVelocity.IsNearlyZero() && !Input.IsNearlyZero())
				Movement.InterpRotationTo(FQuat::MakeFromZX(FVector::UpVector, HorizontalVelocity), SplitToothComp.Settings.AirRotationSpeed);
			
			Movement.AddPendingImpulses();
		}
		else
		{
			Movement.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMove(Movement);
	}
};