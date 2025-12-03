class UTundraRiverBoulderMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Movement;

	ATundraRiverBoulder Boulder;
	UTundraRiverBoulderMovementComponent MoveComp;
	USweepingMovementData Movement;
	bool bReachedEnd = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boulder = Cast<ATundraRiverBoulder>(Owner);
		MoveComp = Boulder.MoveComp;
		Movement = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!Boulder.bIsActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(!Boulder.bIsActive)
			return true;

		if(bReachedEnd)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bReachedEnd = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(Boulder.bIsActive)
			Boulder.StopBoulder();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float ClosestDistance = Boulder.FollowSpline.Get().Spline.GetClosestSplineDistanceToWorldLocation(Boulder.ActorLocation);
		if(Math::IsNearlyEqual(ClosestDistance, Boulder.FollowSpline.Get().Spline.SplineLength))
		{
			bReachedEnd = true;
			return;
		}

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				Movement.AddOwnerVelocity();

				const FTransform ClosestTransform = Boulder.FollowSpline.Get().Spline.GetWorldTransformAtSplineDistance(ClosestDistance);
				const float RubberbandMultiplier = GetRubberbandMultiplier();

				// Add acceleration
				const float CurrentMaxSpeed = Boulder.BaseForwardMaxSpeed * RubberbandMultiplier;
				float Acceleration = GetAccelerationWithDrag(DeltaTime, Boulder.DragAmount, CurrentMaxSpeed);
				Movement.AddAcceleration(ClosestTransform.Rotation.ForwardVector.GetSafeNormal2D() * Acceleration);

				// Add correctional speed
				FVector CorrectionalOffset = (ClosestTransform.Location - Boulder.ActorLocation).VectorPlaneProject(ClosestTransform.Rotation.UpVector);
				float CorrectionalSize = CorrectionalOffset.Size();
				FVector CorrectionalDirection = CorrectionalOffset.GetSafeNormal();

				float CurrentCorrectionalSpeed = CorrectionalSize * Boulder.CorrectionalDeltaMultiplier * RubberbandMultiplier;
				CurrentCorrectionalSpeed = Math::Clamp(CurrentCorrectionalSpeed, 0.0, Boulder.BaseCorrectionalMaxSpeed * RubberbandMultiplier);
				float CurrentCorrectionalDelta = Math::Min(CurrentCorrectionalSpeed * DeltaTime, CorrectionalSize);
				Movement.AddDeltaWithCustomVelocity(CorrectionalDirection * CurrentCorrectionalDelta, FVector::ZeroVector);

				// Add drag
				FVector Drag = GetFrameRateIndependentDrag(MoveComp.Velocity, Boulder.DragAmount, DeltaTime);
				Movement.AddVelocity(Drag);

				// Add gravity
				float CurrentGravityAmount = Boulder.GravityAmount;
				if(Boulder.bAlsoScaleGravityBySpeedScale)
					CurrentGravityAmount *= RubberbandMultiplier;

				Movement.AddAcceleration(FVector::DownVector * CurrentGravityAmount);
			}
			else
			{
				if(MoveComp.HasGroundContact())
					Movement.ApplyCrumbSyncedGroundMovement();
				else
					Movement.ApplyCrumbSyncedAirMovement();
			}
			MoveComp.ApplyMove(Movement);
		}
	}

	/* Returns the acceleration to reach the specified max speed with the specified drag factor */
	float GetAccelerationWithDrag(float DeltaTime, float DragFactor, float MaxSpeed) const
	{
		const float IntegratedDragFactor = Math::Exp(-DragFactor);
		const float NewSpeed = MaxSpeed * Math::Pow(IntegratedDragFactor, DeltaTime);
		float Drag = Math::Abs(NewSpeed - MaxSpeed);

		return Drag / DeltaTime;
	}

	/* Takes in velocity and drag and delta time and returns the velocity to add. */
	FVector GetFrameRateIndependentDrag(FVector Velocity, float Drag, float DeltaTime)
	{
		const float IntegratedDragFactor = Math::Exp(-Drag);
		FVector TargetVelocity = Velocity * Math::Pow(IntegratedDragFactor, DeltaTime);
		return TargetVelocity - Velocity;
	}

	float GetRubberbandMultiplier()
	{
		if(Boulder.BoulderRubberbandingPlayerTarget == ETundraRiverBoulderRubberbandingTarget::None)
			return 1.0;
		
		AHazePlayerCharacter PlayerTarget;
		const float DotToMio = Boulder.ActorForwardVector.DotProduct(Game::Mio.ActorLocation - Boulder.ActorLocation);
		const float DotToZoe = Boulder.ActorForwardVector.DotProduct(Game::Zoe.ActorLocation - Boulder.ActorLocation);
		
		if(Boulder.BoulderRubberbandingPlayerTarget == ETundraRiverBoulderRubberbandingTarget::Mio)
		{
			PlayerTarget = Game::Mio;
		}
		else if(Boulder.BoulderRubberbandingPlayerTarget == ETundraRiverBoulderRubberbandingTarget::Zoe)
		{
			PlayerTarget = Game::Zoe;
		}
		else if(DotToMio < 0.0 || DotToZoe < 0.0)
		{
			// Both players are behind boulder so just use slowest speed.
			if(DotToMio < 0.0 && DotToZoe < 0.0)
				return Boulder.SlowestSpeedScale;

			if(DotToZoe < 0.0)
				PlayerTarget = Game::Mio;
			else
				PlayerTarget = Game::Zoe;
		}
		else if(Boulder.BoulderRubberbandingPlayerTarget == ETundraRiverBoulderRubberbandingTarget::Closest)
		{
			if(DotToMio < DotToZoe)
				PlayerTarget = Game::Mio;
			else
				PlayerTarget = Game::Zoe;
		}
		else if(Boulder.BoulderRubberbandingPlayerTarget == ETundraRiverBoulderRubberbandingTarget::Furthest)
		{
			if(DotToMio > DotToZoe)
				PlayerTarget = Game::Mio;
			else
				PlayerTarget = Game::Zoe;
		}
		else
		{
			devError("Added entry to rubberbanding target enum but forgot to handle it!");
			return 1.0;
		}

		devCheck(PlayerTarget != nullptr, "Player target was null when checking rubberband scale for boulder, this shouldn't happen");
		float DistanceToPlayerTarget = PlayerTarget.ActorLocation.Dist2D(Boulder.ActorLocation);
		const float Dot = Boulder.ActorForwardVector.DotProduct(PlayerTarget.ActorLocation - Boulder.ActorLocation);
		if(Dot < 0.0)
			DistanceToPlayerTarget = 0.0;

		PrintToScreen(f"{Dot=}");
		PrintToScreen(f"{DistanceToPlayerTarget=}");
		PrintToScreen(f"{PlayerTarget.GetName()=}");

		const float Multiplier = Math::GetMappedRangeValueClamped(
			FVector2D(Boulder.ClosestDistance, Boulder.FurthestDistance), 
			FVector2D(Boulder.SlowestSpeedScale, Boulder.FastestSpeedScale), 
			DistanceToPlayerTarget);
		
		return Multiplier;
	}
}