
class UPlayerSlideDashStartupCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Slide);
	default CapabilityTags.Add(PlayerMovementTags::Dash);
	default CapabilityTags.Add(PlayerSlideTags::SlideDash);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 30;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UPlayerSlideDashComponent DashComp;
	UPlayerSlideComponent SlideComp;
	USteppingMovementData Movement;

	float CurrentSpeed;
	FVector Dir;
	float Deceleration;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		DashComp = UPlayerSlideDashComponent::GetOrCreate(Player);
		SlideComp = UPlayerSlideComponent::GetOrCreate(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WasActionStarted(ActionNames::MovementDash))
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

		// if (MoveComp.IsOnValidGround())
		// 	return true;

		if (ActiveDuration > DashComp.Settings.SlowdownTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::Slide, this);

		CurrentSpeed = MoveComp.HorizontalVelocity.Size();
		Deceleration = (CurrentSpeed - DashComp.Settings.SlowdownSpeed) / DashComp.Settings.SlowdownTime;
		Dir = MoveComp.Velocity.GetSafeNormal();
		DashComp.bDashing = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Slide, this);

		DashComp.bForceDash = true;
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{	
				FVector Velocity = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp);
				Velocity -= Velocity.GetSafeNormal() * Deceleration * DeltaTime;

				Movement.AddHorizontalVelocity(Velocity);

				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();

				Movement.SetRotation(Dir.Rotation());
				// Movement.InterpRotationToTargetFacingRotation(6.0);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Slide");   
		}
	}
}