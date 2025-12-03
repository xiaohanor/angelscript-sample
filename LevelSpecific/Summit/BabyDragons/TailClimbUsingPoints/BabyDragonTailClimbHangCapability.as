
class UBabyDragonTailClimbHangCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(n"BabyDragon");
	default CapabilityTags.Add(n"TailClimb");

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 7;
	default TickGroupSubPlacement = 10;

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
		// Activate hang after enter is finished
		if (DragonComp.ClimbState == ETailBabyDragonClimbState::Enter)
		{
			if (!DragonComp.bClimbReachedPoint)
				return false;
			return true;
		}
		// Go back into hang if we're inside transfer but the transfer was canceled
		else if (DragonComp.ClimbState == ETailBabyDragonClimbState::Transfer)
		{
			if (MoveComp.HasMovedThisFrame())
				return false;
			return true;
		}
		else
		{
			return false;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DragonComp.ClimbState != ETailBabyDragonClimbState::Hang)
			return true;
		if (DragonComp.ClimbActivePoint == nullptr)
			return true;
		if (DragonComp.ClimbActivePoint.Owner.IsActorDisabled())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DragonComp.AnimationState.Apply(ETailBabyDragonAnimationState::ClimbHang, this, EInstigatePriority::Low);
		DragonComp.ClimbState = ETailBabyDragonClimbState::Hang;
		DragonComp.LastHangGameTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.AnimationState.Clear(this);
		OffsetComp.ResetOffsetWithLerp(this, 0.2);

		if (DragonComp.ClimbState == ETailBabyDragonClimbState::Hang)
			DragonComp.ClimbState = ETailBabyDragonClimbState::None;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			FTransform TargetTransform = DragonComp.ClimbActivePoint.GetHangTransform();
			OffsetComp.SnapToRotation(this, TargetTransform.Rotation, EInstigatePriority::High);

			Movement.AddDeltaFromMoveToPositionWithCustomVelocity(TargetTransform.Location, FVector::ZeroVector);
			Movement.SetRotation(FRotator::MakeFromX(
				TargetTransform.Rotation.ForwardVector.ConstrainToPlane(FVector::UpVector)
			));
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"BabyDragonClimbing");
		}
	}
}
