
class UPlayerSlideJumpStartupCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Slide);
	default CapabilityTags.Add(PlayerMovementTags::Jump);	
	default CapabilityTags.Add(PlayerSlideTags::SlideJump);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 35;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UPlayerSlideJumpComponent JumpComp;
	UPlayerSlideComponent SlideComp;
	USteppingMovementData Movement;

	float CurrentSpeed;
	FVector Dir;
	float Deceleration;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		JumpComp = UPlayerSlideJumpComponent::GetOrCreate(Player);
		SlideComp = UPlayerSlideComponent::GetOrCreate(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WasActionStarted(ActionNames::MovementJump))
			return false;

		if (!Player.IsAnyCapabilityActive(PlayerSlideTags::SlideMovement))
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!MoveComp.IsOnWalkableGround())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (MoveComp.IsInAir())
			return true;

		if (ActiveDuration > JumpComp.Settings.SlowdownTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::Slide, this);

		CurrentSpeed = MoveComp.HorizontalVelocity.Size();
		Deceleration = (CurrentSpeed - JumpComp.Settings.SlowdownSpeed) / JumpComp.Settings.SlowdownTime;
		Dir = MoveComp.Velocity.GetSafeNormal();
		JumpComp.bStartedJump = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Slide, this);

		JumpComp.bJump = true;
		JumpComp.bStartedJump = false;

	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector Velocity = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp);
				Velocity = Velocity.GetSafeNormal() * CurrentSpeed;
				CurrentSpeed = Math::Max(CurrentSpeed - (Deceleration * DeltaTime), 0.0);

				Movement.AddHorizontalVelocity(Velocity);

				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();

				Movement.SetRotation(Dir.Rotation());
				// Movement.InterpRotationToTargetFacingRotation(6.0);

			#if !RELEASE	
				TEMPORAL_LOG(this)
				.Value("Speed", CurrentSpeed)
				.Value("Deceleration", Deceleration)
				.Value("Velocity", Velocity);
			#endif

			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Slide");   
		}
	}
}