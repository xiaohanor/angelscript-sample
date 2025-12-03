class USkylineRailingSlideMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	USkylineRailingSlideUserComponent UserComp;

	FSplinePosition SplinePosition;
	FVector Offset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		UserComp = USkylineRailingSlideUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		
		if (UserComp.RailingSlide == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (UserComp.RailingSlide == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SplinePosition = UserComp.RailingSlide.Spline.GetClosestSplinePositionToWorldLocation(Owner.ActorLocation);

		float Direction = Owner.ActorVelocity.SafeNormal.DotProduct(SplinePosition.WorldForwardVector);

		if (Direction < 0.0)
			SplinePosition.ReverseFacing();

		Offset = Owner.ActorLocation - SplinePosition.WorldTransform.TransformPositionNoScale(UserComp.RailingSlide.RailingOffset);
	
		FHazePlaySlotAnimationParams AnimationParams;
		AnimationParams.Animation = UserComp.SlidingAnim;
		AnimationParams.bLoop = true;
		Player.PlaySlotAnimation(AnimationParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.StopSlotAnimationByAsset(UserComp.SlidingAnim);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PrintToScreen("RailingSlideMovement", 0.0, FLinearColor::Green);

		FVector Acceleration = -FVector::UpVector * 5000.0;

		FVector Velocity = MoveComp.Velocity;
		Velocity += Acceleration * DeltaTime;
		float SpeedAlpha = Math::Max(0.0, Velocity.DotProduct(SplinePosition.WorldForwardVector));
		float SplineMoveDelta = UserComp.SlideSpeed * DeltaTime;
//		float SplineMoveDelta = SpeedAlpha * DeltaTime;

		if (!SplinePosition.Move(SplineMoveDelta))
		{
			UserComp.RailingSlide = nullptr;
			return;
		}

		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector TargetLocation = Math::Lerp(Offset, FVector::ZeroVector, Math::Min(1.0, ActiveDuration * 10.0));

				FVector SplineLocation = SplinePosition.WorldTransform.TransformPositionNoScale(UserComp.RailingSlide.RailingOffset);
//				FVector SplineLocation = SplinePosition.WorldLocation;

				FQuat Rotation = SplinePosition.WorldTransform.Rotation.RightVector.ToOrientationQuat();
				FVector DeltaMove = (TargetLocation + SplineLocation) - Owner.ActorLocation;

				Movement.AddDeltaFromMoveToPositionWithCustomVelocity(TargetLocation + SplineLocation, FVector::ZeroVector);
//				Movement.AddDelta(DeltaMove);

				Movement.InterpRotationTo(Rotation, 20.0);
			//	Movement.AddVelocity(PogoStick.Velocity);
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(Movement);
		}
	}
};