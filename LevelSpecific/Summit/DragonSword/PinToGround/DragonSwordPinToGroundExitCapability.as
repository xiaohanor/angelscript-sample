class UDragonSwordPinToGroundExitCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordPinToGround);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 90;

	default DebugCategory = SummitDebugCapabilityTags::DragonSword;
	UDragonSwordPinToGroundComponent PinComp;
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	FVector AccumulatedTranslation;
	bool bHasAssignedExitState = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PinComp = UDragonSwordPinToGroundComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PinComp.State != EDragonSwordPinToGroundState::Pinned)
			return false;

		if (PinComp.IsPlayerPinnedToGround())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// TODO: Use more robust solution for exiting this without breaking animations
		if (PinComp.ExitState == EDragonSwordPinToGroundExitAnimState::Moving && ActiveDuration > PinComp.ExitToMovingSequenceData.Duration)
			return true;

		if (PinComp.ExitState == EDragonSwordPinToGroundExitAnimState::Standing && ActiveDuration > PinComp.ExitSequenceData.Duration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PinComp.bIsExitFinished = false;
		bHasAssignedExitState = false;
		AccumulatedTranslation = FVector::ZeroVector;
		PinComp.State = EDragonSwordPinToGroundState::Exit;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PinComp.bIsExitFinished = true;
		PinComp.ExitState = EDragonSwordPinToGroundExitAnimState::None;
		PinComp.State = EDragonSwordPinToGroundState::None;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement))
		{
			return;
		}
		if (HasControl())
		{
			if (!bHasAssignedExitState)
			{
				PinComp.ExitState = MoveComp.MovementInput.IsNearlyZero() ? EDragonSwordPinToGroundExitAnimState::Standing : EDragonSwordPinToGroundExitAnimState::Moving;
				bHasAssignedExitState = true;
			}

			auto ExitSequence = PinComp.ExitSequenceData.Sequence;
			float ExitDuration = PinComp.ExitSequenceData.Duration;
			float ExitMovementLength = PinComp.ExitSequenceData.MovementLength;
			if (PinComp.ExitState == EDragonSwordPinToGroundExitAnimState::Moving)
			{
				ExitSequence = PinComp.ExitToMovingSequenceData.Sequence;
				ExitDuration = PinComp.ExitToMovingSequenceData.Duration;
				ExitMovementLength = PinComp.ExitToMovingSequenceData.MovementLength;
			}

			FVector InputDirection = MoveComp.MovementInput.GetSafeNormal();
			InputDirection = InputDirection.VectorPlaneProject(Player.MovementWorldUp);

			FQuat MovementRotation = Player.ActorQuat;
			if (!InputDirection.IsNearlyZero())
			{
				// Rotate towards input direction
				FQuat TargetRotation = FQuat::MakeFromZX(Player.MovementWorldUp, InputDirection);
				MovementRotation = FQuat::Slerp(Player.ActorQuat, TargetRotation, 6 * DeltaTime);
			}

			FVector RootMovement = PinComp.GetRootMotion(ExitSequence, AccumulatedTranslation, ActiveDuration, ExitMovementLength, ExitDuration);
			RootMovement *= Math::GetMappedRangeValueClamped(FVector2D(0.0, 1.0),
															 FVector2D(1.0, 1.0),
															 MoveComp.MovementInput.Size());

			FVector DeltaMovement = MovementRotation.RotateVector(RootMovement);

			DeltaMovement = DeltaMovement.VectorPlaneProject(MoveComp.WorldUp);
			Movement.AddDelta(DeltaMovement);
			Movement.SetRotation(MovementRotation);

			Movement.AddOwnerVerticalVelocity();
			Movement.AddGravityAcceleration();
		}
		else
		{
			Movement.ApplyCrumbSyncedGroundMovement();
		}
		MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"DragonSwordHoldOn");
	}
};