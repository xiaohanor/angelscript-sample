
struct FBabyDragonTailClimbTransferParams
{
	UBabyDragonTailClimbTargetable Point;
};

struct FBabyDragonTailClimbTransferDeactivationParams
{
	bool bTransferSucceeded = false;
};

class UBabyDragonTailClimbTransferCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(n"BabyDragon");
	default CapabilityTags.Add(n"TailClimb");

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 7;
	default TickGroupSubPlacement = 9;

	UPlayerTailBabyDragonComponent DragonComp;
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UHazeOffsetComponent OffsetComp;
	UPlayerTargetablesComponent TargetablesComp;

	UBabyDragonTailClimbTargetable TargetPoint;
	FHazeRuntimeSpline JumpTrajectory;
	FHazeAcceleratedFloat Speed;
	float PositionInTrajectory = 0.0;
	bool bTransferFinished = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);
		DragonComp = UPlayerTailBabyDragonComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		OffsetComp = Player.GetMeshOffsetComponent();
	}
	
	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (DragonComp.ClimbState == ETailBabyDragonClimbState::Hang
			&& !IsBlocked())
		{
			TargetablesComp.ShowWidgetsForTargetables(
				UBabyDragonTailClimbTargetable,
				DragonComp.ClimbTransferTargetableWidget,
			);
		}
	}
	
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBabyDragonTailClimbTransferParams& Params) const
	{
		if (DragonComp.ClimbState != ETailBabyDragonClimbState::Hang)
			return false;
		if (!WasActionStopped(ActionNames::SecondaryLevelAbility))
			return false;
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (Time::GetGameTimeSince(DragonComp.LastHangGameTime) < BabyDragonTailClimb::ClimbTransferCooldown)
			return false;

		auto PrimaryTarget = TargetablesComp.GetPrimaryTarget(UBabyDragonTailClimbTargetable);
		if (PrimaryTarget == nullptr)
			return false;

		Params.Point = Cast<UBabyDragonTailClimbTargetable>(PrimaryTarget);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FBabyDragonTailClimbTransferDeactivationParams& Params) const
	{
		if (DragonComp.ClimbState != ETailBabyDragonClimbState::Transfer)
			return true;
		if (DragonComp.ClimbActivePoint == nullptr)
			return true;
		if (DragonComp.ClimbActivePoint.Owner.IsActorDisabled())
			return true;

		if (bTransferFinished)
		{
			Params.bTransferSucceeded = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FBabyDragonTailClimbTransferParams Params)
	{
		DragonComp.AnimationState.Apply(ETailBabyDragonAnimationState::ClimbJumpTransfer, this);
		DragonComp.ClimbState = ETailBabyDragonClimbState::Transfer;
		TargetPoint = Params.Point;
		bTransferFinished = false;

		FTransform ActivePointTransform = DragonComp.ClimbActivePoint.GetHangTransform();
		FTransform TargetPointTransform = TargetPoint.GetHangTransform();
		FVector MiddlePoint = ActivePointTransform.Location + TargetPointTransform.Location;
		MiddlePoint *= 0.5;

		FVector OutwardDirection = -TargetPointTransform.Rotation.ForwardVector;
		MiddlePoint += OutwardDirection * BabyDragonTailClimb::ClimbTransferOutwardDistance;

		Speed.SnapTo(0.0);
		PositionInTrajectory = 0.0;

		JumpTrajectory = FHazeRuntimeSpline();
		JumpTrajectory.AddPoint(TargetPointTransform.InverseTransformPositionNoScale(ActivePointTransform.Location));
		JumpTrajectory.AddPoint(TargetPointTransform.InverseTransformPositionNoScale(MiddlePoint));
		JumpTrajectory.AddPoint(FVector::ZeroVector);
		
		UBabyDragonTailClimbEventHandler::Trigger_StartedClimbTransfer(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FBabyDragonTailClimbTransferDeactivationParams Params)
	{
		DragonComp.AnimationState.Clear(this);
		OffsetComp.ResetOffsetWithLerp(this, 0.2);

		if (Params.bTransferSucceeded)
		{
			DragonComp.ClimbActivePoint = TargetPoint;
		}
		else
		{
			if (DragonComp.ClimbState == ETailBabyDragonClimbState::Transfer)
				DragonComp.ClimbState = ETailBabyDragonClimbState::None;
		}

		UBabyDragonTailClimbEventHandler::Trigger_FinishedClimbTransfer(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// If we've been targeting the same point for a while, then move there
		FTransform TargetPointTransform = TargetPoint.GetHangTransform();

		Debug::DrawDebugLine(
			DragonComp.ClimbActivePoint.WorldLocation,
			TargetPoint.WorldLocation,
			FLinearColor::Blue, 5.0
		);

		if (MoveComp.PrepareMove(Movement))
		{
			Speed.AccelerateTo(BabyDragonTailClimb::ClimbTransferSpeed, BabyDragonTailClimb::ClimbTransferAccelerationDuration, DeltaTime);
			PositionInTrajectory += Speed.Value * DeltaTime;

			if (PositionInTrajectory > JumpTrajectory.GetLength())
			{
				bTransferFinished = true;
				PositionInTrajectory = JumpTrajectory.GetLength();
			}

			FVector TargetLocation = JumpTrajectory.GetLocationAtDistance(PositionInTrajectory);
			TargetLocation = TargetPointTransform.TransformPositionNoScale(TargetLocation);

			// Move towards the new point
			Movement.AddDelta(TargetLocation - Player.ActorLocation);
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"BabyDragonClimbing");
		}
	}
}
