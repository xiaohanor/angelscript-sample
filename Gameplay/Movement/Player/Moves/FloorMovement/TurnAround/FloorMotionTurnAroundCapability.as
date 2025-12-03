enum ETurnaroundDebugModes
{
	Default,
	NoStopDuration,
	Disabled
}

class UFloorMotionTurnAroundCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::FloorMotion);
	default CapabilityTags.Add(PlayerFloorMotionTags::FloorMotionTurnAround);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 149;

	UPlayerMovementComponent MoveComp;
	UPlayerSprintComponent SprintComp;
	USteppingMovementData Movement;

	UPlayerFloorMotionComponent FloorMotionComp;

	TArray<FVector> StickHistory;
	int StickHistoryIndex = 0;

	float InactiveTimer = 0.0;

	bool bTurnAroundDetected = false;

	FQuat WantedRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		SprintComp = UPlayerSprintComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		FloorMotionComp = UPlayerFloorMotionComponent::Get(Player);
		StickHistory.SetNum(10);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!IsActive())
			InactiveTimer += DeltaTime;

		bTurnAroundDetected = false;

		FVector MovementDirection = MoveComp.MovementInput;
		StickHistory[StickHistoryIndex] = MovementDirection;
		++StickHistoryIndex;

		if(StickHistoryIndex >= StickHistory.Num())
			StickHistoryIndex = 0;

		FVector Input = MoveComp.MovementInput;
		if((Math::DotToDegrees(Player.ActorForwardVector.DotProduct(Input)) > 120.0)
			&& StickHistoryCheck())
		{
			if(InactiveTimer < 0.3)
				InactiveTimer = 0.0;
			else
				bTurnAroundDetected = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(FloorMotionComp.TurnaroundModes == ETurnaroundDebugModes::Disabled)
			return false;

		if(MoveComp.HasMovedThisFrame())
			return false;

		if(SprintComp.IsSprinting())
			return false;

		if(!MoveComp.IsOnWalkableGround() || MoveComp.HasUpwardsImpulse())
			return false;

		if(!bTurnAroundDetected)
			return false;

		return true;	
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		//Hard Coded value, should this be part of floor motion settings?
		if(ActiveDuration >= 0.125 && FloorMotionComp.TurnaroundModes != ETurnaroundDebugModes::NoStopDuration)
			return true;

		if(FloorMotionComp.TurnaroundModes == ETurnaroundDebugModes::NoStopDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		//Assign inactive timer to 0.
		InactiveTimer = 0.0;

		FloorMotionComp.AnimData.bTurnaroundTriggered = true;

		//Store our wanted direction based on input when we detect a turnaround
		FVector MovementDirection = MoveComp.SyncedMovementInputForAnimationOnly.GetSafeNormal();
		WantedRotation = (MovementDirection.ToOrientationQuat());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		FloorMotionComp.AnimData.bTurnaroundTriggered = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				Movement.SetRotation(WantedRotation);
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Movement");
		}
	}

	bool StickHistoryCheck() const
	{
		const FVector CurrentMoveDirection = MoveComp.MovementInput;

		if(CurrentMoveDirection.IsNearlyZero())	
			return false;

		FQuat Rot = FQuat::MakeFromXZ(CurrentMoveDirection, MoveComp.WorldUp);

		const FVector CurrentInputForward = Rot.ForwardVector;
		const FVector CurrentInputRightVector = Rot.RightVector;

		bool bStickWasInOtherDirection = false;

		for (const FVector& PastStick : StickHistory)
		{
			if(PastStick.IsNearlyZero())
				continue;

			if(Math::Abs(CurrentInputRightVector.DotProduct(PastStick)) > 0.5)
				continue;

			if(CurrentInputForward.DotProduct(PastStick) < 0.0)
				bStickWasInOtherDirection = true;
		}

		return bStickWasInOtherDirection;
	}
}