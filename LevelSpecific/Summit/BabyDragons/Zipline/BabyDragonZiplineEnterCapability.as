struct FBabyDragonZiplineEnterParams
{
	ABabyDragonZiplinePoint Point;
};

class UBabyDragonZiplineEnterCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(n"BabyDragon");
	default CapabilityTags.Add(n"Zipline");

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 4;
	default TickGroupSubPlacement = 1;

	UPlayerTailBabyDragonComponent DragonComp;
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerTargetablesComponent TargetablesComp;

	FHazeAcceleratedVector Speed;
	float TargetSplineDistance = 0.0;
	bool bStartedGrounded = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);
		DragonComp = UPlayerTailBabyDragonComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}
	
	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if ((DragonComp.ZiplineState == ETailBabyDragonZiplineState::None
			|| DragonComp.ZiplineState == ETailBabyDragonZiplineState::Follow)
			&& DragonComp.ClimbState == ETailBabyDragonClimbState::None
			&& !IsBlocked())
		{
			TargetablesComp.ShowWidgetsForTargetables(
				UBabyDragonZiplineTargetable,
				DragonComp.ZiplineTargetableWidget,
			);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBabyDragonZiplineEnterParams& Params) const
	{
		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;
		if (MoveComp.HasMovedThisFrame())
        	return false;
		if (DragonComp.ClimbState != ETailBabyDragonClimbState::None)
			return false;
		if (DragonComp.ZiplineState != ETailBabyDragonZiplineState::None
			&& DragonComp.ZiplineState != ETailBabyDragonZiplineState::Follow)
			return false;

		auto PrimaryTarget = TargetablesComp.GetPrimaryTarget(UBabyDragonZiplineTargetable);
		if (PrimaryTarget == nullptr)
			return false;

		Params.Point = Cast<ABabyDragonZiplinePoint>(PrimaryTarget.Owner);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DragonComp.ZiplineState != ETailBabyDragonZiplineState::Enter)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FBabyDragonZiplineEnterParams Params)
	{
		DragonComp.AnimationState.Apply(ETailBabyDragonAnimationState::ZiplineEnter, this);
		DragonComp.ZiplineState = ETailBabyDragonZiplineState::Enter;
		DragonComp.ZiplineActivePoint = Params.Point;
		DragonComp.bZiplineReachedLine = false;

		Speed.SnapTo(FVector::ZeroVector);

		TargetSplineDistance = DragonComp.ZiplineActivePoint.ZiplineTargetable.GetEnterDistanceOnSpline(Player);
		DragonComp.ZiplinePosition = FSplinePosition(DragonComp.ZiplineActivePoint.SplineComp, TargetSplineDistance, true);
		bStartedGrounded = MoveComp.HasGroundContact();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.AnimationState.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FTransform TargetTransform = DragonComp.ZiplineActivePoint.SplineComp.GetWorldTransformAtSplineDistance(TargetSplineDistance);
		FVector TargetLocation = TargetTransform.TransformPosition(BabyDragonZipline::PlayerZiplineOffset);
		Player.SetMovementFacingDirection(TargetTransform.Rotation.ForwardVector.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal());

		if (MoveComp.PrepareMove(Movement))
		{
			if(!bStartedGrounded || ActiveDuration > BabyDragonZipline::AnticipationDelay)
			{
				if (!DragonComp.bZiplineReachedLine)
				{
					FVector RemainingDelta = (TargetLocation - Player.ActorLocation);
					FVector Direction = RemainingDelta.GetSafeNormal();

					Speed.AccelerateTo(Direction * BabyDragonZipline::EnterSpeed, BabyDragonZipline::EnterAccelerationDuration, DeltaTime);

					FVector MoveDelta = Speed.Value * DeltaTime;
					if (MoveDelta.Size() >= RemainingDelta.Size())
					{
						Movement.AddDelta(RemainingDelta);
						DragonComp.bZiplineReachedLine = true;
					}
					else
					{
						Movement.AddDelta(MoveDelta);
					}
				}
				else
				{
					Movement.AddDeltaFromMoveToPositionWithCustomVelocity(TargetLocation, FVector::ZeroVector);
				}
			}

			Movement.InterpRotationToTargetFacingRotation(800.0);
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"BackpackDragonZipline");
			DragonComp.RequestBabyDragonLocomotion(n"BackpackDragonZipline");
		}
	}
}