
class UPlayerSlideDashCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Slide);
	default CapabilityTags.Add(PlayerMovementTags::Dash);
	default CapabilityTags.Add(PlayerSlideTags::SlideDash);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 37;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerSlideDashComponent DashComp;
	UPlayerSprintComponent SprintComp;

	FVector Dir;
	float ExitSpeed;
	float CurrDashCooldown;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		DashComp = UPlayerSlideDashComponent::GetOrCreate(Player);
		SprintComp = UPlayerSprintComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!MoveComp.IsOnWalkableGround())
			return false;

		if (!DashComp.bForceDash)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (ActiveDuration >= DashComp.Settings.DashDuration)
			return true;

		if (MoveComp.HasUpwardsImpulse())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::Slide, this);

		DashComp.bForceDash = false;

		// Set ExitSpeed and direction depending on if we are moving or standing still
		ExitSpeed = 950.0;

		Dir = MoveComp.MovementInput.GetSafeNormal();
		if(MoveComp.MovementInput.IsNearlyZero())
		{
			Dir = Player.ActorForwardVector;
			ExitSpeed = 500.0;
		}

		// Set start velocity for the move
		Player.SetActorVelocity(Dir * DashComp.Settings.EnterSpeed);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Slide, this);

		CurrDashCooldown = 0.0;
		DashComp.bDashing = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (IsActioning(ActionNames::MovementVerticalDown) && MoveComp.IsOnWalkableGround())
			ExitSpeed = 1500.0;
		else
			ExitSpeed = 950.0;

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				// Calculate speed based on how far into the move we are
				float Alpha = ActiveDuration / DashComp.Settings.DashDuration;
				float CurvedAlpha = DashComp.DashCurve.GetFloatValue(Alpha);
				float Speed = Math::Lerp(ExitSpeed, DashComp.Settings.EnterSpeed, CurvedAlpha);

				// If we have stick input, set it to be the target direction of the dash, otherwise keep going in the same direction we already are
				FVector TargetDir = MoveComp.MovementInput.GetSafeNormal();
				if(MoveComp.MovementInput.IsNearlyZero())
					TargetDir = Player.ActorForwardVector;

				// Interpolate towards target direction and calculate final velocity
				FVector Direction = Math::VInterpTo(Player.ActorForwardVector, TargetDir, DeltaTime, DashComp.Settings.TurnRate);
				FVector Velocity = Direction * Speed;

				Movement.SetRotation(MoveComp.GetRotationBasedOnVelocity());
				Movement.AddHorizontalVelocity(Velocity);
				Movement.AddGravityAcceleration();
				Movement.AddOwnerVerticalVelocity();
				Movement.InterpRotationToTargetFacingRotation(15.0);
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}
			
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Slide");
		}

	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		CurrDashCooldown += DeltaTime;
	}
};