class UBabyDragonTailClimbJumpOffCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(n"BabyDragon");
	default CapabilityTags.Add(n"TailClimb");

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 7;
	default TickGroupSubPlacement = 8;

	UPlayerTailBabyDragonComponent DragonComp;
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UHazeOffsetComponent OffsetComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTailBabyDragonComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		OffsetComp = Player.GetMeshOffsetComponent();
	}
	
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DragonComp.ClimbState != ETailBabyDragonClimbState::Hang)
			return false;
		if (!WasActionStarted(ActionNames::MovementJump))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DragonComp.AnimationState.Apply(ETailBabyDragonAnimationState::ClimbExitJumpOff, this);
		DragonComp.ClimbState = ETailBabyDragonClimbState::None;
		OffsetComp.FreezeRotationAndLerpBackToParent(this, 0.2);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.AnimationState.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			FVector Impulse;
			Impulse += FVector::UpVector * BabyDragonTailClimb::JumpOffVerticalSpeed;

			FVector ForwardTowardWall = DragonComp.ClimbActivePoint.GetHangTransform().Rotation.ForwardVector;
			Impulse += ForwardTowardWall * -BabyDragonTailClimb::JumpOffHorizontalSpeed;

			Movement.AddVelocity(Impulse);
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"BabyDragonClimbing");
		}
	}
}