class UMagnetDroneAttachToBoatJumpCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(MagnetDroneTags::AttachToBoat);
	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileAttraction);
	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileAttached);
	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileInMagnetDroneBounce);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 71;

	UMagnetDroneAttachToBoatComponent AttachToBoatComp;
	UMagnetDroneComponent DroneComp;
	UMagnetDroneJumpComponent JumpComp;
	UHazeMovementComponent MoveComp;

	private float LastJumpTime = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AttachToBoatComp = UMagnetDroneAttachToBoatComponent::Get(Player);
		DroneComp = UMagnetDroneComponent::Get(Player);
		JumpComp = UMagnetDroneJumpComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!AttachToBoatComp.IsAttachedToBoat())
			return false;

		if(!AttachToBoatComp.bHasLandedOnBoat)
			return false;

		// It's possible for this jump capability to activate the same frame as the relative jump, if they deactivate/activate on the same frame.
		// Checking here that if we stopped jumping this frame, don't allow jumping again.
		if(JumpComp.StoppedJumpingThisFrame())
			return false;

		if(!JumpComp.WasJumpInputStartedThisFrame())
			return false;

		if(MoveComp.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.IsOnWalkableGround())
			return true;

		if(AttachToBoatComp.IsAttachedToBoat())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		JumpComp.ConsumeJumpInput();

		AttachToBoatComp.DetachFromBoat();

		// If we are moving over a certain speed (say we dashed or rolled very quickly), limit horizontal speed
		if(MoveComp.HorizontalVelocity.Size() > DroneComp.MovementSettings.JumpMaxHorizontalSpeed)
		{
			FVector ClampedHorizontalVelocity = MoveComp.HorizontalVelocity.GetClampedToMaxSize(DroneComp.MovementSettings.JumpMaxHorizontalSpeed);
			Player.SetActorHorizontalVelocity(ClampedHorizontalVelocity);
		}

		FVector Impulse = FVector::UpVector * DroneComp.MovementSettings.JumpImpulse;

		// Limit max vertical impulse to prevent super high jumps
		float CurrentSpeedInJumpDirection = Player.ActorVelocity.DotProduct(FVector::UpVector);
		if(CurrentSpeedInJumpDirection > DroneComp.MovementSettings.JumpImpulse)
		{
			// If we are already moving fast upwards, don't jump
			Impulse = FVector::ZeroVector;
		}
		else
		{
			Impulse -= FVector::UpVector * CurrentSpeedInJumpDirection;
		}

		Player.AddMovementImpulse(Impulse);
		
		JumpComp.ApplyIsJumping(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		JumpComp.ClearIsJumping(this);
	}
};