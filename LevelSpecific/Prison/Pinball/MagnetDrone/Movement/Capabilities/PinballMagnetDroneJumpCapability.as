class UPinballMagnetDroneJumpCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(Pinball::Tags::ControlJump);

	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileAttraction);
	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileAttached);

	default CapabilityTags.Add(Pinball::Tags::BlockedWhileInRail);
	default CapabilityTags.Add(Pinball::Tags::BlockedWhileLaunched);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 80;

	UMagnetDroneJumpComponent JumpComp;
	UPinballMagnetDroneComponent PinballComp;
	UPinballBallComponent BallComp;
	UPinballMagnetDroneLaunchedComponent LaunchedComp;

	UHazeMovementComponent MoveComp;
	UPinballMagnetDroneMovementData MoveData;

	private float JumpGraceTimer = BIG_NUMBER;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JumpComp = UMagnetDroneJumpComponent::Get(Player);
		PinballComp = UPinballMagnetDroneComponent::Get(Player);
		BallComp = UPinballBallComponent::Get(Player);
		LaunchedComp = UPinballMagnetDroneLaunchedComponent::Get(Player);

		MoveComp = UHazeMovementComponent::Get(Player);
		MoveData = MoveComp.SetupMovementData(UPinballMagnetDroneMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;

		if(!WasActionStartedDuringTime(ActionNames::MovementJump, PinballComp.MovementSettings.JumpInputBufferTime))
			return false;

		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!IsInJumpGracePeriod())
			return false;

		if(LaunchedComp.WasLaunched())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.IsOnAnyGround())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementJump);

		const FVector WorldUp = Pinball::GetWorldUp();
		const FVector WorldRight = Pinball::GetWorldRight(WorldUp);

		JumpComp.ApplyIsJumping(this, WorldUp);

		if (HasControl())
		{
			FVector HorizontalVelocity = MoveComp.Velocity.ProjectOnTo(WorldRight);
			FVector TargetVelocity = HorizontalVelocity + (WorldUp * PinballComp.MovementSettings.JumpImpulse);
			FVector Impulse = TargetVelocity - MoveComp.Velocity;
			Player.AddMovementImpulse(Impulse);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		JumpComp.ClearIsJumping(this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(IsBlockedByTag(MagnetDroneTags::BlockedWhileAttached))
			JumpGraceTimer = BIG_NUMBER;
		else if (MoveComp.IsInAir())
			JumpGraceTimer += DeltaTime;
		else
			JumpGraceTimer = 0.0;
	}

	bool IsInJumpGracePeriod() const
	{
		return JumpGraceTimer <= PinballComp.MovementSettings.JumpGraceTime;
	}
}