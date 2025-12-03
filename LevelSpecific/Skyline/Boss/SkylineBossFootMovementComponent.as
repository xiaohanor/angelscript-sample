class USkylineBossFootMovementComponent : UActorComponent
{
	ASkylineBoss Boss;
	TMap<ESkylineBossLeg, FSkylineBossFootMoveData> FeetMovementData;
	float LastFootPlacementTimestamp = MIN_flt;
	float LastStepTimeStamp = MIN_flt;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Boss = Cast<ASkylineBoss>(Owner);
	}

	bool CanStep() const
	{
		check(HasControl());
		
		auto& MovementData = Boss.MovementQueue[0];
		// Traversal is finished, waiting on last leg to finish step
		return MovementData.CurrentStep+1 < MovementData.FootTargets.Num();
	}

	ESkylineBossLeg NewStep()
	{
		check(HasControl());
		
		FSkylineBossMovementData& MovementData = Boss.MovementQueue[0];
		
		// First step of the move, event!
		if (MovementData.CurrentStep == 0)
		{
			Boss.OnTraversalBegin.Broadcast(Boss.CurrentHub, MovementData.ToHub);
		}


		MovementData.bIsStepping = true;

		// Note that we also modify the struct, and that the value will start at 1
		//  which is intended because the first foot should always be correctly planted
		++MovementData.CurrentStep;
		if(MovementData.LegPlacementOrderTransitionIndex == MovementData.CurrentStep)
		{
			MovementData.LegPlacementOrder = MovementData.NextLegPlacementOrder;
		}
		if(MovementData.BodyRotationTransitionIndex == MovementData.CurrentStep)
		{
			MovementData.SplineActor = MovementData.NextSplineActor;
			MovementData.bIsReversed = MovementData.bNextIsReversed;
		}

		// One cycle is three steps, every step correlates to a leg
		//  the move defines the order of the placement (e.g left, center, right)
		//  then we have to take rebased order into account (done in GetLegComponent)
		ESkylineBossLeg Leg = MovementData.LegPlacementOrder[MovementData.CurrentStep % 3];
		if(!FeetMovementData.Contains((Leg)))
		{
			FeetMovementData.Add(Leg, FSkylineBossFootMoveData());
		}
		
		FeetMovementData[Leg].LegComponent = Boss.GetLegComponent(Leg);

		FSkylineBossFootMoveData& Data = FeetMovementData[Leg];

		// Find next foot target
		auto FootTargets = MovementData.FootTargets;
		Data.FootTarget = FootTargets[MovementData.CurrentStep];

		FRotator Rotation;
		FeetMovementData[Leg].LegComponent.Leg.GetFootLocationAndRotation(Data.StartLocation, Rotation);

		Data.StartFootUpVector = Rotation.UpVector;
		//AcceleratedLocation.SnapTo(Location);
		Data.AcceleratedRotation.SnapTo(Rotation.Quaternion());

		// Using the leg component's stored foot target, since that is where our foot was based
		FSkylineBossFootEventData FootLiftData;
		FootLiftData.FootTargetComponent = Data.LegComponent.FootTargetComponent;
		Data.LegComponent.Leg.GetFootLocationAndRotation(FootLiftData.FootLocation, FootLiftData.FootRotation);
		FootLiftData.Leg = Data.LegComponent.Leg;
		USkylineBossEventHandler::Trigger_FootLifted(Boss, FootLiftData);
		Data.LegComponent.FootTargetComponent.OnFootLifted.Broadcast();
		Boss.OnFootLifted.Broadcast(FootLiftData.Leg);

		CrumbNewStep(Data.LegComponent);

		Data.StepTimeStamp = Time::GameTimeSeconds;
		LastStepTimeStamp = Time::GameTimeSeconds;
	
		FVector MoveDirection = (Data.FootTarget.WorldLocation - Data.LegComponent.Leg.GetFootLocation()).VectorPlaneProject(FVector::UpVector);
		Data.PitchAxis = MoveDirection.CrossProduct(FVector::UpVector).GetSafeNormal();

		UpdateLegPlacementForward(Data, MovementData, Leg);

		// MovementData.FromHub.GetClosestSplineEndIndex(MovementData.SplineActor.Spline, MovementData.FromHub.ActorLocation, bIsStartingPoint);
		// MovementData.bIsReversed = !bIsStartingPoint;
		// Print("Is reversed: " + MovementData.bIsReversed);

		return Leg;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbNewStep(USkylineBossLegComponent LegComponent)
	{
		LegComponent.Leg.bPlacingStarted = false;
		LegComponent.bIsGrounded = false;
	}

	private void UpdateLegPlacementForward(FSkylineBossFootMoveData& Data, FSkylineBossMovementData MovementData, ESkylineBossLeg Leg) const
	{
		check(HasControl());

		if(MovementData.IsRebasing())
		{
			FVector FromHubToTarget = (Data.FootTarget.WorldLocation - MovementData.ToHub.ActorLocation).GetSafeNormal2D();
			Data.LegComponent.PlacementForward = FromHubToTarget;
			return;
		}

		// Get the spline direction closest to the foot target
		// We will rotate this direction and use it as the foot placement forward direction
		FVector ClosestSplineDir = MovementData.SplineActor.Spline.GetClosestSplineWorldRotationToWorldLocation(Data.FootTarget.WorldLocation).ForwardVector;

		// Flip the direction if we are reversed
		if(MovementData.bIsReversed)
		 	ClosestSplineDir *= -1;

		// Based on the leg index, rotate the rotation
		switch(Leg)
		{
			case ESkylineBossLeg::Left:
				// Rotate 60 degrees left
				Data.LegComponent.PlacementForward = FQuat(FVector::UpVector, Math::DegreesToRadians(-60)) * ClosestSplineDir;
				break;

			case ESkylineBossLeg::Right:
				// Rotate 60 degrees right
				Data.LegComponent.PlacementForward = FQuat(FVector::UpVector, Math::DegreesToRadians(60)) * ClosestSplineDir;
				break;

			case ESkylineBossLeg::Center:
				// Face backwards
				Data.LegComponent.PlacementForward = -ClosestSplineDir;
				break;
		}
	}

	void HandleFootMovement(ESkylineBossLeg Leg, float DeltaTime)
	{
		check(HasControl());

		FSkylineBossFootMoveData& Foot = FeetMovementData[Leg];

		FTemporalLog TemporalLog = TEMPORAL_LOG(Boss);
		TemporalLog.Arrow(f"To foot target{Leg}", Foot.StartLocation, Foot.FootTarget.WorldLocation, 100, 50);

		if(Foot.LegComponent.bIsGrounded)
			return;

		float Alpha = Math::Clamp(Time::GetGameTimeSince(Foot.StepTimeStamp) / Boss.Settings.StepDuration, 0.0, 1.0);

		if(!Foot.LegComponent.Leg.bPlacingStarted)
		{
			if(Alpha > 0.7)
			{
				OnFootPlacingStarted(Foot);
			}
		}
		else if(Alpha == 1)
		{
			FinishStep(Foot);
		}

		FVector NewLocation = GetTargetLocation(Foot, Alpha, DeltaTime);
		FQuat TargetRotation = GetTargetRotation(Foot, Alpha, DeltaTime);
	

		Foot.LegComponent.Leg.SetFootAnimationTargetLocationAndRotation(
			NewLocation,
			TargetRotation.Rotator()
		);
	}

	private FQuat GetTargetRotation(FSkylineBossFootMoveData& Foot, float Alpha, float DeltaTime) const
	{
		check(HasControl());

		//PITCH OFFSET
		float AngleAlpha = Boss.Settings.FootStepRotationCurve.GetFloatValue(Alpha);
		const float StepDistSqr = Foot.StartLocation.DistSquared(Foot.FootTarget.WorldLocation);
		const float MaxStepDistSqr = Boss.Settings.StepMaxPitchDistance * Boss.Settings.StepMaxPitchDistance;
		const float PitchMultiplier = Math::Clamp(StepDistSqr / MaxStepDistSqr, 0, 1);
		float PitchValue = Boss.Settings.StepMaxPitch * PitchMultiplier;
		float Angle = Math::DegreesToRadians(AngleAlpha * PitchValue);
		FQuat PitchOffset = FQuat(Foot.PitchAxis, -Angle);

		float TimeRemaining = Math::Max(Boss.Settings.StepDuration - Time::GetGameTimeSince(Foot.StepTimeStamp), 0.0);
		FVector TargetUpVector = Math::Lerp(Foot.StartFootUpVector, Foot.FootTarget.UpVector, Alpha);
		//FQuat TargetRotation = FQuat::MakeFromZX(TargetUpVector, Foot.LegComponent.Leg.ActorForwardVector);
		FQuat TargetRotation = FQuat::MakeFromZX(TargetUpVector, Foot.LegComponent.PlacementForward);

		TargetRotation = Foot.AcceleratedRotation.AccelerateTo(TargetRotation, TimeRemaining, DeltaTime);
		TargetRotation = PitchOffset * TargetRotation;
		return TargetRotation;
	}

	private FVector GetTargetLocation(FSkylineBossFootMoveData& Foot, float Alpha, float DeltaTime) const
	{
		check(HasControl());

		float VerticalOffsetFactor = Math::Sin(PI * Alpha);
		if (Boss.Settings.FootStepCurve != nullptr)
			VerticalOffsetFactor = Boss.Settings.FootStepCurve.GetFloatValue(Alpha);

		FVector VerticalOffset = FVector::UpVector * Boss.Settings.StepHeight * VerticalOffsetFactor;
		const float SpeedAlpha = Boss.Settings.FootStepSpeedCurve.GetFloatValue(Alpha);
		return Math::Lerp(Foot.StartLocation, Foot.FootTarget.WorldLocation, SpeedAlpha) + VerticalOffset;
	}

	private void OnFootPlacingStarted(FSkylineBossFootMoveData& Foot)
	{
		check(HasControl());

		FSkylineBossFootEventData FootPrePlacedData;
		FootPrePlacedData.FootTargetComponent = Foot.LegComponent.FootTargetComponent;
		Foot.LegComponent.Leg.GetFootLocationAndRotation(FootPrePlacedData.FootLocation, FootPrePlacedData.FootRotation);
		FootPrePlacedData.Leg = Foot.LegComponent.Leg;
		CrumbOnFootPlacingStarted(FootPrePlacedData);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnFootPlacingStarted(FSkylineBossFootEventData FootPrePlacedData)
	{
		FootPrePlacedData.Leg.bPlacingStarted = true;
		FootPrePlacedData.Leg.OwningLegComp.Leg.bPlacingStarted = true;
		USkylineBossEventHandler::Trigger_FootPlacingStart(Boss, FootPrePlacedData);
	}

	private void FinishStep(FSkylineBossFootMoveData& Foot)
	{
		check(HasControl());

		auto& MovementData = Boss.MovementQueue[0];

		LastFootPlacementTimestamp = Time::GameTimeSeconds;

		// Update the referenced foot target component and then call the events
		Foot.LegComponent.FootTargetComponent = Foot.FootTarget;
		Foot.LegComponent.Leg.bPlacingStarted = false;
		Foot.LegComponent.bIsGrounded = true;
		Foot.LegComponent.FootTargetComponent.OnFootPlaced.Broadcast();


		FSkylineBossFootEventData FootPlacedData;
		FootPlacedData.FootTargetComponent = Foot.LegComponent.FootTargetComponent;
		Foot.LegComponent.Leg.GetFootLocationAndRotation(FootPlacedData.FootLocation, FootPlacedData.FootRotation);
		FootPlacedData.Leg = Foot.LegComponent.Leg;
		CrumbFinishStep(FootPlacedData);

		if (MovementData.IsCompleted())
		{
			bool bFail = false;
			for(auto FootData : FeetMovementData)
			{
				if(!FootData.Value.LegComponent.bIsGrounded)
					bFail = true;
			}

			if(!bFail)
				Boss.TraversalToHubCompleted();
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbFinishStep(FSkylineBossFootEventData FootPlacedData)
	{
		USkylineBossEventHandler::Trigger_FootPlaced(Boss, FootPlacedData);
		FootPlacedData.Leg.bPlacingStarted = false;
		FootPlacedData.Leg.OwningLegComp.bIsGrounded = true;
		Boss.OnFootPlaced.Broadcast(FootPlacedData.Leg);
	}
};