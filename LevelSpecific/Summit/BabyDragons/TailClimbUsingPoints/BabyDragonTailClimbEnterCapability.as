
struct FBabyDragonTailClimbEnterParams
{
	UBabyDragonTailClimbTargetable Point;
	bool bIsGroundedEnter = false;
};

class UBabyDragonTailClimbEnterCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(n"BabyDragon");
	default CapabilityTags.Add(n"TailClimb");

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 7;
	default TickGroupSubPlacement = 1;

	UPlayerTailBabyDragonComponent DragonComp;
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UHazeOffsetComponent OffsetComp;
	UPlayerTargetablesComponent TargetablesComp;

	float Speed;
	bool bGroundedEnter = false;

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
		if (DragonComp.ClimbState == ETailBabyDragonClimbState::None
			&& !IsBlocked())
		{
			TargetablesComp.ShowWidgetsForTargetables(
				UBabyDragonTailClimbTargetable,
				DragonComp.ClimbEnterTargetableWidget,
			);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBabyDragonTailClimbEnterParams& Params) const
	{
		if (!WasActionStarted(ActionNames::SecondaryLevelAbility))
			return false;
		if (MoveComp.HasMovedThisFrame())
        	return false;
		if (DragonComp.ClimbState != ETailBabyDragonClimbState::None)
			return false;

		auto PrimaryTarget = TargetablesComp.GetPrimaryTarget(UBabyDragonTailClimbTargetable);
		if (PrimaryTarget == nullptr)
			return false;

		Params.Point = Cast<UBabyDragonTailClimbTargetable>(PrimaryTarget);
		Params.bIsGroundedEnter = MoveComp.IsOnWalkableGround();
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DragonComp.ClimbState != ETailBabyDragonClimbState::Enter)
			return true;
		if (DragonComp.ClimbActivePoint == nullptr)
			return true;
		if (DragonComp.ClimbActivePoint.Owner.IsActorDisabled())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FBabyDragonTailClimbEnterParams Params)
	{
		DragonComp.ClimbState = ETailBabyDragonClimbState::Enter;
		DragonComp.ClimbActivePoint = Params.Point;
		DragonComp.bClimbReachedPoint = false;
		bGroundedEnter = Params.bIsGroundedEnter;

		if (bGroundedEnter)
			DragonComp.AnimationState.Apply(ETailBabyDragonAnimationState::ClimbEnterGrounded, this);
		else
			DragonComp.AnimationState.Apply(ETailBabyDragonAnimationState::ClimbEnterAirborne, this);

		Speed = 0.0;

		FTransform TargetTransform = DragonComp.ClimbActivePoint.GetHangTransform();
		OffsetComp.LerpToRotation(this, TargetTransform.Rotation, 0.3);

		UBabyDragonTailClimbEventHandler::Trigger_StartedClimbEnter(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.AnimationState.Clear(this);
		OffsetComp.ResetOffsetWithLerp(this, 0.2);

		UBabyDragonTailClimbEventHandler::Trigger_FinishedClimbEnter(Player);

		if (DragonComp.ClimbState == ETailBabyDragonClimbState::Enter)
			DragonComp.ClimbState = ETailBabyDragonClimbState::None;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			FTransform TargetTransform = DragonComp.ClimbActivePoint.GetHangTransform();

			if (!DragonComp.bClimbReachedPoint)
			{
				FVector RemainingDelta = (TargetTransform.Location - Player.ActorLocation);
				FVector Direction = RemainingDelta.GetSafeNormal();

				float SetupSpeed = 0.0;
				float JumpedSpeed = 0.0;
				float SetupDuration = 0.0;
				if (bGroundedEnter)
				{
					SetupDuration = BabyDragonTailClimb::GroundedEnterSetupTime;
					SetupSpeed = BabyDragonTailClimb::GroundedEnterSetupSpeed;
					JumpedSpeed = BabyDragonTailClimb::GroundedEnterJumpedSpeed;
				}
				else
				{
					SetupDuration = BabyDragonTailClimb::AirborneEnterSetupTime;
					SetupSpeed = BabyDragonTailClimb::AirborneEnterSetupSpeed;
					JumpedSpeed = BabyDragonTailClimb::AirborneEnterJumpedSpeed;
				}

				float TargetSpeed = JumpedSpeed;

				// During setup we move slower
				if (ActiveDuration < SetupDuration)
				{
					TargetSpeed = SetupSpeed;

					// For a grounded enter, we don't leave the ground during the setup
					if (bGroundedEnter)
						Direction = Direction.ConstrainToPlane(MoveComp.WorldUp);
				}

				Speed = Math::FInterpConstantTo(Speed, TargetSpeed, BabyDragonTailClimb::EnterSpeedAcceleration, DeltaTime);

				FVector MoveDelta = Direction * Speed * DeltaTime;
				FVector CorrectDelta = MoveDelta.ProjectOnToNormal(Direction);
				if (CorrectDelta.Size() >= RemainingDelta.Size())
				{
					Movement.AddDelta(RemainingDelta);
					DragonComp.bClimbReachedPoint = true;
				}
				else
				{
					Movement.AddDelta(MoveDelta);
				}
			}
			else
			{
				Movement.AddDeltaFromMoveToPositionWithCustomVelocity(TargetTransform.Location, FVector::ZeroVector);
			}

			Movement.SetRotation(FRotator::MakeFromX(
				TargetTransform.Rotation.ForwardVector.ConstrainToPlane(FVector::UpVector)
			));
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"BabyDragonClimbing");
		}
	}
}