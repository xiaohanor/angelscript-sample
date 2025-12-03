class UPinballMagnetMoveCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(Pinball::Tags::Pinball);
	default CapabilityTags.Add(Pinball::Tags::PinballMovement);

	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileAttraction);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 90;	// Before BaseDroneMovement

	UHazeMovementComponent MoveComp;
	UMagnetDroneComponent DroneComp;
	UMagnetDroneAttachedComponent AttachedComp;
	UPinballMagnetDroneComponent PinballComp;
	UPinballMagnetAttachedMovementData MoveData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Player);
		DroneComp = UMagnetDroneComponent::Get(Player);
		AttachedComp = UMagnetDroneAttachedComponent::Get(Player);
		MoveData = MoveComp.SetupMovementData(UPinballMagnetAttachedMovementData);

		PinballComp = UPinballMagnetDroneComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;

		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!AttachedComp.IsAttachedToSurface())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(!AttachedComp.IsAttachedToSurface())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UMagnetDroneAttachedSettings::SetOnlyAlignWithMagneticContacts(Owner, true, this);
		UMagnetDroneAttachedSettings::SetAlignWithNonMagneticFlatGround(Owner, false, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UMagnetDroneAttachedSettings::ClearOnlyAlignWithMagneticContacts(Owner, this);
		UMagnetDroneAttachedSettings::ClearAlignWithNonMagneticFlatGround(Owner, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaTime)
	{
		// set new world up for the movement that is gonna be calculated
		if(!MoveComp.PrepareMove(MoveData, FVector::BackwardVector))
			return;

		// Make sure that the player is facing the correct direction
		MoveData.InterpRotationTo(DroneComp.CalculateDesiredRotation().Quaternion(), MagnetDrone::RotateSpeed, false);

		MoveData.UseGroundStickynessThisFrame();

		CalculateDeltaMove(FVector::BackwardVector, DeltaTime);

		MoveData.AddPendingImpulses();

		MoveComp.ApplyMove(MoveData);
	} 

	void CalculateDeltaMove(FVector WorldUp, float DeltaTime) const
	{
		FVector Velocity = MoveComp.Velocity;
		FVector MovementInput = FVector(0, GetAttributeFloat(AttributeNames::MoveRight), GetAttributeFloat(AttributeNames::MoveForward));
		
		FVector VerticalVelocity = Velocity.ProjectOnTo(WorldUp);
		FVector HorizontalVelocity = Velocity - VerticalVelocity;
	
		const bool bIsInputting = !MovementInput.IsNearlyZero();

		if(bIsInputting)
		{
			const bool bIsRebound = HorizontalVelocity.DotProduct(MovementInput) < 0;

			float Acceleration = PinballComp.MovementSettings.MagnetAcceleration;
			if(bIsRebound)
				Acceleration *= Math::Lerp(1, PinballComp.MovementSettings.ReboundMultiplier, MovementInput.Size());

			FVector Force = MovementInput * Acceleration;
			HorizontalVelocity += (Force * DeltaTime);

			// If we accelerated past the max, clamp
			if(IsOverHorizontalMaxSpeed(HorizontalVelocity))
				HorizontalVelocity = HorizontalVelocity.GetClampedToMaxSize(PinballComp.MovementSettings.MagnetMaxMoveSpeed);
		}

		HorizontalVelocity = Math::VInterpConstantTo(HorizontalVelocity, FVector::ZeroVector, DeltaTime, AttachedComp.Settings.Deceleration);

		if(IsOverHorizontalMaxSpeed(HorizontalVelocity))
		{
			// Decelerate if over max speed
			HorizontalVelocity = HorizontalVelocity.GetClampedToMaxSize(AttachedComp.Settings.MaxHorizontalSpeed);
		}

		// Gravity
		VerticalVelocity -= WorldUp * PinballComp.MovementSettings.Gravity * DeltaTime;

		Velocity = HorizontalVelocity + VerticalVelocity;

		MoveData.AddVelocity(Velocity);
	}

	bool IsOverHorizontalMaxSpeed(FVector HorizontalVelocity) const
	{
		return HorizontalVelocity.Size() > PinballComp.MovementSettings.MagnetMaxMoveSpeed;
	}
};