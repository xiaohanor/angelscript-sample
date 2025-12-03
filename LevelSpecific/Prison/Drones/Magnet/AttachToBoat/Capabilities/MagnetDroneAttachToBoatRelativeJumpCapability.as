class UMagnetDroneAttachToBoatRelativeJumpCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(MagnetDroneTags::AttachToBoat);
	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileAttraction);
	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileAttached);
	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileInMagnetDroneBounce);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 70;	// Before UMagnetDroneJumpCapability

	UMagnetDroneAttachToBoatComponent AttachToBoatComp;
	UMagnetDroneComponent DroneComp;
	UMagnetDroneJumpComponent JumpComp;
	UPlayerMovementComponent MoveComp;

	bool bHasReachedApex = false;
	FVector ApexHorizontalOffset;
	float ApexVerticalOffset;
	float TimeToLand;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AttachToBoatComp = UMagnetDroneAttachToBoatComponent::Get(Player);
		DroneComp = UMagnetDroneComponent::Get(Player);
		JumpComp = UMagnetDroneJumpComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!AttachToBoatComp.IsAttachedToBoat())
			return false;

		if(!AttachToBoatComp.Settings.bJumpRelativeToBoat)
			return false;

		if(!JumpComp.WasJumpInputStartedDuringTime(DroneComp.MovementSettings.JumpInputBufferTime))
			return false;

		if(!AttachToBoatComp.bHasLandedOnBoat)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!AttachToBoatComp.IsAttachedToBoat())
			return true;

		if(!AttachToBoatComp.Settings.bJumpRelativeToBoat)
			return true;

		if(AttachToBoatComp.bHasLandedOnBoat)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		JumpComp.ConsumeJumpInput();

		AttachToBoatComp.RelativeJump();

		JumpComp.ApplyIsJumping(this);

		bHasReachedApex = false;

		AttachToBoatComp.bIsPerformingRelativeJump = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		JumpComp.ClearIsJumping(this);

		AttachToBoatComp.AccHorizontalOffset.SnapTo(FVector::ZeroVector);

		AttachToBoatComp.bIsPerformingRelativeJump = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			// We only tick on control and don't apply movement since that is still handled by UMagnetDroneAttachToBoatCapability
			ControlMovement(DeltaTime);
		}
	}

	void ControlMovement(float DeltaTime)
	{
		check(HasControl());

		if(AttachToBoatComp.VerticalSpeed > 0)
		{
			// While moving up, apply default drone air movement

			FVector Delta = FVector::ZeroVector;
			FVector Velocity = AttachToBoatComp.AccHorizontalOffset.Velocity;
			FVector MovementInput = FVector(GetAttributeFloat(AttributeNames::MoveForward), GetAttributeFloat(AttributeNames::MoveRight), 0);
			FRotator InputRotation = FRotator::MakeFromZX(FVector::UpVector, Player.ViewRotation.ForwardVector);
			MovementInput = InputRotation.RotateVector(MovementInput);

			Drone::TickAirMove(
				Delta,
				Velocity,
				MovementInput,
				DeltaTime,
				DroneComp.MovementSettings.AirMaxHorizontalSpeed,
				DroneComp.MovementSettings.AirMaxSpeedDeceleration,
				DroneComp.MovementSettings.AirReboundMultiplier,
				DroneComp.MovementSettings.AirAcceleration * 0.5,
				DroneComp.MovementSettings.AirMaxFallSpeed,
				DroneComp.MovementSettings.AirMaxFallDeceleration
			);

			// Apply it only as horizontal movement.
			// Falling/vertical movement is handled by the main attach capability.

			Delta.Z = 0;
			Velocity.Z = 0;

			AttachToBoatComp.AccHorizontalOffset.Value += Delta;
			AttachToBoatComp.AccHorizontalOffset.Velocity = Velocity;
		}
		else
		{
			if(!bHasReachedApex)
			{
				// Once we start falling, store our apex state
				bHasReachedApex = true;
				ApexHorizontalOffset = AttachToBoatComp.AccHorizontalOffset.Value;
				ApexVerticalOffset = AttachToBoatComp.VerticalOffset;

				TimeToLand = AttachToBoatComp.CalculateTimeToLand();
			}

			// Accelerate away our horizontal offset
			AttachToBoatComp.AccHorizontalOffset.AccelerateTo(FVector::ZeroVector, TimeToLand, DeltaTime);
		}
	}
};