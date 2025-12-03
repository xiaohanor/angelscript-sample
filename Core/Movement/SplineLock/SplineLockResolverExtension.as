enum EPlayerSplineLockStatus
{
    Unset,
    Entering,
    Locked,
    Leaving,
};

/**
 * Restricts movement to a spline.
 * Applied with static functions in SplineLockStatics.as
 */
class USplineLockResolverExtension : UMovementResolverExtension
{
	default SupportedResolverClasses.Add(UBaseMovementResolver);

	access SplineLockComp = private, USplineLockComponent (inherited);
	access Resolver = private, UBaseMovementResolver (inherited);

	UBaseMovementResolver Resolver;
	bool bShouldApplySplineLock = false;

	FSplinePosition CurrentSplinePosition;
	EPlayerSplineLockStatus SplineLockStatus = EPlayerSplineLockStatus::Unset;
	FPlayerMovementSplineLockProperties SplineLockProperties;
	
	/**
	 * How far are we from the spline horizontally?
	 * > 0 == Right
	 * < 0 == Left
	 */
	float CurrentDeviation = 0;
	float CapsuleRadius = -1;
	float IterationTime = -1;
	float MoveIntoSmoothnessDistance = -1;

	bool bAppliedConstraint = false;
	float OriginalDeviation;

#if !RELEASE
	bool bDebugForwardAndWorldUpParallel = false;
	FSplinePosition DebugFirstIterationSplineLocation;
	FTransform DebugSplineLockTransform;
#endif

#if EDITOR
	void CopyFrom(const UMovementResolverExtension OtherBase) override
	{
		Super::CopyFrom(OtherBase);
		
		auto Other = Cast<USplineLockResolverExtension>(OtherBase);
		Resolver = Other.Resolver;
		bShouldApplySplineLock = Other.bShouldApplySplineLock;

		CurrentSplinePosition = Other.CurrentSplinePosition;
		SplineLockStatus = Other.SplineLockStatus;
		SplineLockProperties = Other.SplineLockProperties;

		CurrentDeviation = Other.CurrentDeviation;
		CapsuleRadius = Other.CapsuleRadius;
		IterationTime = Other.IterationTime;
		MoveIntoSmoothnessDistance = Other.MoveIntoSmoothnessDistance;

		OriginalDeviation = Other.OriginalDeviation;
	}
#endif

	void PrepareExtension(UBaseMovementResolver InResolver, const UBaseMovementData InMoveData) override
	{
		Super::PrepareExtension(InResolver, InMoveData);

		Resolver = InResolver;
		bShouldApplySplineLock = Resolver.ShouldApplySplineLock();

		if(!bShouldApplySplineLock)
			return;
		
		USplineLockComponent SplineLockComp = USplineLockComponent::Get(InResolver.Owner);

		devCheck(SplineLockComp != nullptr, "Can't resolve movement with " + this + " since " + Resolver.Owner + " dont have a SplineLockComponent");
		devCheck(SplineLockComp.HasActiveSplineLock(), "Can't resolve movement with " + this + " since " + Resolver.Owner + " is not locked on a spline");
		devCheck(SplineLockComp.CurrentSpline != nullptr, "Can't resolve movement with " + this + " since " + Resolver.Owner + " is not locked on a spline");

		CurrentSplinePosition = SplineLockComp.GetSplinePosition();
		SplineLockStatus = SplineLockComp.SplineLockStatus;
		SplineLockProperties = SplineLockComp.GetCurrentSettings().LockSettings;

		CurrentDeviation = 0;
		CapsuleRadius = Math::Max(InMoveData.ShapeSizeForMovement, 1);
		IterationTime = Resolver.IterationTime;

		const EPlayerSplineLockPlaneType PlaneLockType = SplineLockProperties.LockType;
		const FVector WorldUp = Resolver.CurrentWorldUp;
		check(WorldUp.IsUnit());
		FVector UpVector = SplineLock::GetUpVector(PlaneLockType, CurrentSplinePosition, WorldUp);
		FVector WantedMovementDelta = Resolver.IterationState.DeltaToTrace.VectorPlaneProject(UpVector);

		// If we force the input along the spline
		// we should never be able to deviate from it
		SplineLockProperties.AllowedHorizontalDeviation = Math::Max(SplineLockProperties.AllowedHorizontalDeviation, 1);
		// if(SplineLockProperties.bConstrainMovementInput)
		// 	SplineLockProperties.AllowedHorizontalDeviation = 1;
		// else
		// 	SplineLockProperties.AllowedHorizontalDeviation = Math::Max(SplineLockProperties.AllowedHorizontalDeviation, 1);
		
		MoveIntoSmoothnessDistance = -1;
		if(SplineLockComp.GetCurrentSettings().EnterSettings != nullptr)
			MoveIntoSmoothnessDistance = SplineLockComp.GetCurrentSettings().EnterSettings.MoveIntoSmoothnessDistance;
		MoveIntoSmoothnessDistance = Math::Max(MoveIntoSmoothnessDistance, CapsuleRadius);

		if(SplineLockProperties.bCanLeaveSplineAtEnd)
		{
			switch(PlaneLockType)
			{
				case EPlayerSplineLockPlaneType::Horizontal:
				{
					//const FVector WantedLocation = Move.CurrentLocation + WantedMovementDelta;
					
					FSplinePosition ClosestSplinePositionToWantedPlayerLocation = CurrentSplinePosition;
					const FVector SplineForward = SplineLock::GetMovementForward(PlaneLockType, ClosestSplinePositionToWantedPlayerLocation, UpVector);
					if(SplineLockStatus == EPlayerSplineLockStatus::Locked)
					{
						// What direction on the spline do we want to move on
						const float SplineDot = WantedMovementDelta.GetSafeNormal().DotProduct(SplineForward);
						if(!ClosestSplinePositionToWantedPlayerLocation.Move(SplineDot))
						{
							SplineLockStatus = EPlayerSplineLockStatus::Leaving;
						}
					}
					else if(SplineLockStatus == EPlayerSplineLockStatus::Locked)
					{
						FVector SplineWorldLocation = SplineForward + Resolver.IterationState.CurrentLocation.ProjectOnToNormal(UpVector);
						FVector DirToSpline = (SplineWorldLocation - Resolver.IterationState.CurrentLocation).GetSafeNormal();
						if(DirToSpline.DotProduct(WantedMovementDelta) > 0)
						{
							SplineLockStatus = EPlayerSplineLockStatus::Entering;
						}
					}

					break;
				}

				case EPlayerSplineLockPlaneType::SplinePlane:
					break;

				case EPlayerSplineLockPlaneType::SplinePlaneAllowMovingWithinHorizontalDeviation:
					break;
			}
		}

		OriginalDeviation = SplineLock::GetSplinePositionDeviation(PlaneLockType, CurrentSplinePosition, Resolver.IterationState.CurrentLocation, Resolver.IterationState.WorldUp);
		bAppliedConstraint = false;

#if EDITOR
		DebugSplineLockTransform = CurrentSplinePosition.CurrentSpline.WorldTransform;
#endif
	}

	bool OnPrepareNextIteration(bool bFirstIteration) override
	{
		Super::OnPrepareNextIteration(bFirstIteration);

		if(!bShouldApplySplineLock)
			return true;
		
		if(bFirstIteration)
		{
#if EDITOR
			if(bIsEditorRerunExtension)
			{
				devCheck(CurrentSplinePosition.CurrentSpline != nullptr, "Can't rerun movement with " + this + " since the spline information has been deleted");
				devCheck(CurrentSplinePosition.CurrentSpline.WorldTransform.Equals(DebugSplineLockTransform), "Can't rerun against moving spline. Add a 'TemporalLogTransformEditorComponent' to the owner of the spline");
			}
#endif

			PrepareFirstIteration(Resolver.IterationState);
		}

		return PrepareIteration(Resolver.CurrentWorldUp);
	}

	/**
	 * We start by redirecting all the movement deltas towards the spline direction
	 * so we are moving fairly close to the spline.
	 * for now, we are not using any substep but if the movement is to fast,
	 * this might be a requirement in order to follow the spline more correctly
	 */
	private void PrepareFirstIteration(FMovementResolverState& State)
	{
		if(!ensure(bShouldApplySplineLock))
			return;

		const EPlayerSplineLockPlaneType PlaneLockType = GetPlaneLockType();

		switch(PlaneLockType)
		{
			case EPlayerSplineLockPlaneType::Horizontal:
			{
				FVector UpVector = SplineLock::GetUpVector(PlaneLockType, CurrentSplinePosition, State.WorldUp);

				// We start with updating the spline location, in case, the spline moved
				CurrentSplinePosition = SplineLock::GetClosestSplineHorizontalLocation(
					CurrentSplinePosition.CurrentSpline, 
					State.CurrentLocation, 
					UpVector, 
					CapsuleRadius * 2);

				CurrentDeviation = SplineLock::GetSplinePositionDeviation(PlaneLockType, CurrentSplinePosition, State.CurrentLocation, State.WorldUp);

				const TMap<EMovementIterationDeltaStateType,FMovementDeltaWithWorldUp>& DeltaStates = State.GetDeltaStates();
				for(auto DeltaState : DeltaStates)
				{
					FMovementDelta HorizontalDelta = DeltaState.Value.ConvertToDelta().GetHorizontalPart(UpVector);
					if(HorizontalDelta.IsNearlyZero())
						continue;
					
					HorizontalDelta = GetConstrainMovementDeltaState(HorizontalDelta, State.WorldUp);
					State.OverrideHorizontalDelta(DeltaState.Key, HorizontalDelta, UpVector);
					bAppliedConstraint = true;
				}

				break;
			}

			case EPlayerSplineLockPlaneType::SplinePlane:
			{
				CurrentSplinePosition = CurrentSplinePosition.CurrentSpline.GetClosestSplinePositionToWorldLocation(State.CurrentLocation);
				CurrentDeviation = SplineLock::GetSplinePositionDeviation(PlaneLockType, CurrentSplinePosition, State.CurrentLocation, State.WorldUp);
				
				const TMap<EMovementIterationDeltaStateType,FMovementDeltaWithWorldUp>& DeltaStates = State.GetDeltaStates();
				for(auto DeltaState : DeltaStates)
				{
					FMovementDelta HorizontalDelta = DeltaState.Value.ConvertToDelta();
					if(HorizontalDelta.IsNearlyZero())
						continue;
					
					HorizontalDelta = GetConstrainMovementDeltaState(HorizontalDelta, State.WorldUp);
					State.OverrideDelta(DeltaState.Key, HorizontalDelta);
					bAppliedConstraint = true;
				}

				break;
			}

			case EPlayerSplineLockPlaneType::SplinePlaneAllowMovingWithinHorizontalDeviation:
			{
				const FVector CurrentLocation = State.CurrentLocation;
				const FVector NextLocation = State.CurrentLocation + State.GetDelta().Delta;

				CurrentSplinePosition = CurrentSplinePosition.CurrentSpline.GetClosestSplinePositionToWorldLocation(CurrentLocation);
				CurrentDeviation = SplineLock::GetSplinePositionDeviation(PlaneLockType, CurrentSplinePosition, CurrentLocation, State.WorldUp);
				const float NewDeviation = SplineLock::GetSplinePositionDeviation(PlaneLockType, CurrentSplinePosition, NextLocation, State.WorldUp);

				// Add slight safety distance
				const float AllowedHorizontalDeviation = Math::Max(1, SplineLockProperties.AllowedHorizontalDeviation - 1);

				if(Math::Abs(NewDeviation) < AllowedHorizontalDeviation)
				{
					// We have not yet gone past the deviation plane
					// No constraining needed
					break;
				}

				if(SplineLockStatus == EPlayerSplineLockStatus::Leaving || SplineLockStatus == EPlayerSplineLockStatus::Unset)
					break;

				const FVector RightVector = SplineLock::GetDeviationRight(PlaneLockType, CurrentSplinePosition, State.WorldUp);
				const FPlane SplinePlane = FPlane(CurrentSplinePosition.WorldLocation, RightVector);
				const float SideSign = Math::Sign(SplinePlane.PlaneDot(CurrentLocation));
				const FVector DeviationNormal = RightVector * SideSign;
				const FPlane DeviationPlane = FPlane(
					CurrentSplinePosition.WorldLocation + (DeviationNormal * AllowedHorizontalDeviation),
					DeviationNormal
				);

				float32 Time = 0;
				FVector Intersection = FVector::ZeroVector;
				if(Math::LinePlaneIntersection(CurrentLocation, NextLocation, DeviationPlane, Time, Intersection))
				{
					// We have moved through the edge

					TMap<EMovementIterationDeltaStateType, float> MovementInfluence;
					float FullDistance = 0;

					for(auto It : State.DeltaStates)
					{
						float& StateInfluence = MovementInfluence.FindOrAdd(It.Key);
						StateInfluence = 0;

						FMovementDelta MovementDelta = It.Value.ConvertToDelta();
						if(MovementDelta.IsNearlyZero())
							continue;

						StateInfluence = MovementDelta.Delta.DotProduct(DeviationNormal);
						if(StateInfluence > 0)
							FullDistance += StateInfluence;
					}
					
					for(auto It : State.DeltaStates)
					{
						const float StateInfluence = MovementInfluence[It.Key];

						if(StateInfluence <= 0)
							continue;

						FMovementDelta MovementDelta = It.Value.ConvertToDelta();
						MovementDelta *= StateInfluence / FullDistance;

						if(KeepDeltaSize())
						{
							const FMovementDelta OriginalMovementDelta = It.Value.ConvertToDelta();
							MovementDelta.Delta = MovementDelta.Delta.GetSafeNormal() * OriginalMovementDelta.Delta.Size();
							MovementDelta.Velocity = MovementDelta.Velocity.GetSafeNormal() * OriginalMovementDelta.Velocity.Size();
						}

						State.OverrideDelta(It.Key, MovementDelta);
					}
				}
				else
				{
					// We have already moved past the edge

					for(auto It : State.DeltaStates)
					{
						const FMovementDelta OriginalMovementDelta = It.Value.ConvertToDelta();
						FMovementDelta MovementDelta = OriginalMovementDelta;
						if(MovementDelta.IsNearlyZero())
							continue;

						// Clamp any deltas moving into the edge direction
						if(MovementDelta.Delta.DotProduct(DeviationNormal) > 0)
						{
							MovementDelta.Delta = MovementDelta.Delta.VectorPlaneProject(DeviationNormal);

							if(KeepDeltaSize())
								MovementDelta.Delta = MovementDelta.Delta.GetSafeNormal() * OriginalMovementDelta.Delta.Size();

							bAppliedConstraint = true;
						}

						if(MovementDelta.Velocity.DotProduct(DeviationNormal) > 0)
						{
							MovementDelta.Velocity = MovementDelta.Velocity.VectorPlaneProject(DeviationNormal);

							if(KeepDeltaSize())
								MovementDelta.Velocity = MovementDelta.Velocity.GetSafeNormal() * OriginalMovementDelta.Velocity.Size();

							bAppliedConstraint = true;
						}

						State.OverrideDelta(It.Key, MovementDelta);
					}
				}
			}
		}

#if !RELEASE
		DebugFirstIterationSplineLocation = CurrentSplinePosition;
#endif
	}

	/**
	 * This function validates that the spline is actually possible to move along
	 */
	private bool PrepareIteration(FVector WorldUp)
	{
		if(!ensure(bShouldApplySplineLock))
			return true;

#if !RELEASE
		bDebugForwardAndWorldUpParallel = false;
		if(GetPlaneLockType() == EPlayerSplineLockPlaneType::Horizontal)
			bDebugForwardAndWorldUpParallel = CurrentSplinePosition.WorldForwardVector.Parallel(WorldUp, SplineLock::ParallelThreshold);
#endif

 		return true;
	}

	private FMovementDelta GetConstrainMovementDeltaState(FMovementDelta OriginalDeltaState, FVector MovementWorldUp) const
	{
		if(!ensure(bShouldApplySplineLock))
			return OriginalDeltaState;

		if(SplineLockStatus == EPlayerSplineLockStatus::Leaving || SplineLockStatus == EPlayerSplineLockStatus::Unset)
			return OriginalDeltaState;

		if(OriginalDeltaState.IsNearlyZero())
			return OriginalDeltaState;

		if(!CurrentSplinePosition.IsValid())
			return OriginalDeltaState;

		const EPlayerSplineLockPlaneType PlaneLockType = GetPlaneLockType();

		switch(PlaneLockType)
		{
			case EPlayerSplineLockPlaneType::Horizontal:
			{
				FVector UpVector = SplineLock::GetUpVector(PlaneLockType, CurrentSplinePosition, MovementWorldUp);
				FVector HorizontalSplineForward = SplineLock::GetMovementForward(PlaneLockType, CurrentSplinePosition, MovementWorldUp);
				if(HorizontalSplineForward.IsNearlyZero())
					return OriginalDeltaState;

				FMovementDelta MovementDelta = OriginalDeltaState;
				const FMovementDelta Horizontal = OriginalDeltaState.GetHorizontalPart(UpVector);
				const FMovementDelta Vertical = OriginalDeltaState.GetVerticalPart(UpVector);

				if(KeepDeltaSize())
				{
					// Velocity
					float VelocityDir = Math::Sign(Horizontal.Velocity.DotProduct(HorizontalSplineForward));
					MovementDelta.Velocity = HorizontalSplineForward * Horizontal.Velocity.Size() * VelocityDir;
					MovementDelta.Velocity += Vertical.Velocity;
				}
				else
				{
					// Velocity
					MovementDelta.Velocity = Horizontal.Velocity.ProjectOnToNormal(HorizontalSplineForward);
					MovementDelta.Velocity += Vertical.Velocity;
				}

				return MovementDelta;
			}

			case EPlayerSplineLockPlaneType::SplinePlane:
			{
				FVector RightVector = SplineLock::GetDeviationRight(PlaneLockType, CurrentSplinePosition, MovementWorldUp);

				FMovementDelta HorizontalDelta = OriginalDeltaState.GetHorizontalPart(MovementWorldUp);
				HorizontalDelta = HorizontalDelta.PlaneProject(RightVector, KeepDeltaSize());

				// Never maintain vertical size, because then velocity along into the plane can cause us to shoot up or down
				FMovementDelta VerticalDelta = OriginalDeltaState.GetVerticalPart(MovementWorldUp);
				VerticalDelta = VerticalDelta.PlaneProject(RightVector, false);

				return (HorizontalDelta + VerticalDelta);
			}

			case EPlayerSplineLockPlaneType::SplinePlaneAllowMovingWithinHorizontalDeviation:
			{
				// This is implemented in PrepareFirstIteration instead to modify all delta states at once, instead of one at a time
				check(false);
				return OriginalDeltaState;
			}
		}
	}

	void OnUnhinderedPendingLocation(FVector& UnhinderedPendingLocation) const override
	{
		if(!bShouldApplySplineLock)
			return;
		
		UnhinderedPendingLocation = GetFinalDeviation(Resolver.IterationState.CurrentLocation, UnhinderedPendingLocation, Resolver.CurrentWorldUp);
	}

	private bool KeepDeltaSize() const
	{
		check(bShouldApplySplineLock);

		switch(SplineLockProperties.KeepDeltaSize)
		{
			case ESplineLockKeepDeltaSize::KeepDeltaSizeWhenMovementInputIsRedirected:
				return SplineLockProperties.bRedirectMovementInput;
			
			case ESplineLockKeepDeltaSize::KeepDeltaSizeAlways:
				return true;

			case ESplineLockKeepDeltaSize::DontKeepDeltaSize:
				return false;
		}
	}

	/**
	 * If we allow deviation, we calculate how far of from the spline center we can be
	 * During the enter phase, we try to reach the actual spline so we move into the borders of the allowed deviation
	 */
	private FVector GetFinalDeviation(FVector OriginalLocation, FVector CurrentLocation, FVector MovementWorldUp) const
	{
		check(bShouldApplySplineLock);

		const EPlayerSplineLockPlaneType PlaneLockType = GetPlaneLockType();

		const FVector WorldRightVector = SplineLock::GetDeviationRight(PlaneLockType, CurrentSplinePosition, MovementWorldUp);
		const FVector UpVector = SplineLock::GetUpVector(PlaneLockType, CurrentSplinePosition, MovementWorldUp);
		const FVector MoveDirection = SplineLock::GetMovementForward(PlaneLockType, CurrentSplinePosition, MovementWorldUp);
		const FVector SplineMovementDelta = CurrentLocation - OriginalLocation;

		switch(PlaneLockType)
		{
			// In the horizontal movement, we will be locked to move along the spline direction
			// but we can also deviate in the splines right direction.
			case EPlayerSplineLockPlaneType::Horizontal:
			{
				const FVector DirToOriginalSplineLoc = (CurrentSplinePosition.WorldLocation - CurrentLocation).VectorPlaneProject(UpVector).GetSafeNormal();
				const float SplineSide = Math::Sign(DirToOriginalSplineLoc.DotProduct(WorldRightVector));
				const FVector HorizontalDeltaStateDirection = (CurrentLocation - OriginalLocation).VectorPlaneProject(UpVector).GetSafeNormal();
				float DeviationAmount = Math::Abs(CurrentDeviation);
				
				// If we have reached the max deviation amount while entering
				// we can now lock unto the spline
				if(SplineLockStatus == EPlayerSplineLockStatus::Entering)
				{	
					const float MoveAmount = (CurrentLocation - OriginalLocation).Size();
					const float MovingTowardsSplineAlpha = Math::Abs(DirToOriginalSplineLoc.DotProduct(HorizontalDeltaStateDirection)) * SplineSide;
					const float Multiplier = Math::Lerp(0.25, 1, Math::Max(MovingTowardsSplineAlpha, 0));
					DeviationAmount -= MoveAmount * Multiplier;
					DeviationAmount = Math::Max(DeviationAmount, 0);
				}
				else
				{		
					DeviationAmount = Math::Min(DeviationAmount, SplineLockProperties.AllowedHorizontalDeviation);
				}
				
				FVector DeviationDirection = WorldRightVector * SplineSide;	
				DeviationAmount = Math::Abs(DeviationAmount - Math::Abs(CurrentDeviation));

				const FVector DeviationDelta = DeviationDirection * DeviationAmount;
				const FVector FinalSplineLocation = CurrentLocation + DeviationDelta;
				
				// If we can't leave the spline at the end,
				// we need to move backwards to the splines end position
				if(SplineLockProperties.bCanLeaveSplineAtEnd)
					return FinalSplineLocation;
		
				const float SplineMovementDeltaAmount = SplineMovementDelta.DotProduct(MoveDirection);

				// If we are moving 
				if(Math::Abs(SplineMovementDeltaAmount) < SMALL_NUMBER)
					return FinalSplineLocation;

				FSplinePosition TempPosition = CurrentSplinePosition;
				if(TempPosition.Move(SplineMovementDeltaAmount))
					return FinalSplineLocation;

				FVector DeltaToSplineLocation = (CurrentSplinePosition.WorldLocation - CurrentLocation).ProjectOnToNormal(MoveDirection);
				return FinalSplineLocation + DeltaToSplineLocation;
			}

			// In the spline plane type, we will be locked in the splines "plane".
			// We can still deviate in the splines right vector.
			case EPlayerSplineLockPlaneType::SplinePlane:
			{
				const FVector DeltaToOriginalSplineLoc = (CurrentSplinePosition.WorldLocation - CurrentLocation).ProjectOnToNormal(WorldRightVector);
				const FVector DirToOriginalSplineLoc = DeltaToOriginalSplineLoc.GetSafeNormal();
				const float SplineSide = Math::Sign(DirToOriginalSplineLoc.DotProduct(WorldRightVector));

				// During the enter 
				FVector FinalSplineLocation = CurrentLocation;
				if(SplineLockStatus == EPlayerSplineLockStatus::Entering)
				{	
					float MoveAmount = (CurrentLocation - OriginalLocation).Size();

					FVector DeviationDirection = WorldRightVector * SplineSide;
					FinalSplineLocation = CurrentLocation + (DeviationDirection * MoveAmount);
				}
				else
				{
					FVector Delta = (CurrentSplinePosition.WorldLocation - CurrentLocation).ProjectOnToNormal(WorldRightVector);
					FinalSplineLocation += Delta;	
				}

				if(SplineLockProperties.bCanLeaveSplineAtEnd)
					return FinalSplineLocation;

				const float SplineMovementDeltaAmount = SplineMovementDelta.DotProduct(MoveDirection);
				FSplinePosition TempPosition = CurrentSplinePosition;
				if(TempPosition.Move(SplineMovementDeltaAmount))
					return FinalSplineLocation;
				
				FVector DeltaToSplineLocation = (CurrentSplinePosition.WorldLocation - CurrentLocation).ProjectOnToNormal(MoveDirection);
				return FinalSplineLocation + DeltaToSplineLocation;
			}

			case EPlayerSplineLockPlaneType::SplinePlaneAllowMovingWithinHorizontalDeviation:
			{
				return CurrentLocation;
			}
		}
	}

	private EPlayerSplineLockPlaneType GetPlaneLockType() const
	{
		return SplineLockProperties.LockType;
	}

	private UHazeSplineComponent GetCurrentSpline() const
	{
		return CurrentSplinePosition.CurrentSpline;
	}

	void PostApplyResolvedData(UHazeMovementComponent MovementComponent) override
	{
		Super::PostApplyResolvedData(MovementComponent);

		if(!bShouldApplySplineLock)
			return;
		
		auto SplineLockComp = USplineLockComponent::Get(MovementComponent.HazeOwner);
		SplineLockComp.ApplySplineLock(CurrentSplinePosition, Resolver.IterationState.CurrentLocation, Resolver.CurrentWorldUp);

		const EPlayerSplineLockPlaneType PlaneLockType = GetPlaneLockType();

		// If we add more types, we need to implement that here
		FVector UpVector = SplineLock::GetUpVector(PlaneLockType, CurrentSplinePosition, Resolver.CurrentWorldUp);

		CurrentDeviation = SplineLock::GetSplinePositionDeviation(PlaneLockType, CurrentSplinePosition, Resolver.IterationState.CurrentLocation, UpVector);

		// We have reached the spline and can now lock it
		if(SplineLockComp.SplineLockStatus == EPlayerSplineLockStatus::Entering)
		{
			if(Math::Abs(CurrentDeviation) < SplineLockProperties.AllowedHorizontalDeviation + KINDA_SMALL_NUMBER)
			{
				// We are within the allowed horizontal deviation, we are now locked
				SplineLockComp.SplineLockStatus = EPlayerSplineLockStatus::Locked;
			}

			if(Math::Sign(CurrentDeviation) != Math::Sign(OriginalDeviation))
			{
				// We have gone over the center line, we are now locked
				SplineLockComp.SplineLockStatus = EPlayerSplineLockStatus::Locked;
			}
		}

		SplineLockStatus = SplineLockComp.SplineLockStatus;

		if(bAppliedConstraint)
		{
			SplineLockComp.LastConstraintFrame = Time::FrameNumber;
			SplineLockComp.LastConstraintDeviation = CurrentDeviation;
		}
	}

#if !RELEASE
	FTemporalLog GetTemporalLogPage(FTemporalLog MovementPageLog, int SortOrder) const override
	{
		return MovementPageLog.Page("Spline Lock");
	}

	void LogPostIteration(FTemporalLog IterationSectionLog) const override
	{
		Super::LogPostIteration(IterationSectionLog);
		
		IterationSectionLog.Value("Current Deviation", CurrentDeviation);
		IterationSectionLog.Value("Original Deviation", OriginalDeviation);

		if(bDebugForwardAndWorldUpParallel)
			IterationSectionLog.Status("Forward and World Up was parallel!", FLinearColor::Red);
	}

	void LogFinal(FTemporalLog ExtensionPage, FTemporalLog FinalSectionLog) const override
	{
		Super::LogFinal(ExtensionPage, FinalSectionLog);

		const EPlayerSplineLockPlaneType PlaneLockType = GetPlaneLockType();
		const FVector WorldUp = Resolver.CurrentWorldUp;

		if(bShouldApplySplineLock && SplineLockProperties.bRedirectMovementInput)
			ExtensionPage.Status("Constrained Movement and Input Redirected", FLinearColor::Green);
		else if(SplineLockProperties.bRedirectMovementInput)
			ExtensionPage.Status("Only Input Redirected", FLinearColor::Yellow);
		else if(bShouldApplySplineLock)
			ExtensionPage.Status("Only Constrained Movement", FLinearColor::Yellow);
		else
			ExtensionPage.Status("Neither Constrained Movement or Input Redirected", FLinearColor::Red);

		FinalSectionLog.Section("Settings", 0)
			.Value("Current Spline", GetCurrentSpline())
			.Value("Spline Lock Status", SplineLockStatus)
			.Value("Plane Lock Type", PlaneLockType)
			.Value("bShouldApplySplineLock", bShouldApplySplineLock)
			.Value("Current Deviation", CurrentDeviation)
			.Value("Allowed Deviation", SplineLockProperties.AllowedHorizontalDeviation)
			.Value("Can Leave Spline At End", SplineLockProperties.bCanLeaveSplineAtEnd)
			.Value("Redirect Movement Input", SplineLockProperties.bRedirectMovementInput)
			.Value("Redirect Initial Velocity Along Spline", SplineLockProperties.bConstrainInitialVelocityAlongSpline)
		;

		const FVector DeviationRight = SplineLock::GetDeviationRight(PlaneLockType, CurrentSplinePosition, WorldUp);
		FinalSectionLog.Section("Deviation", 1)
			.Value("Original Deviation", OriginalDeviation)
			.Value("Current Deviation", CurrentDeviation)
			.Plane("Allowed Deviation Left", DebugFirstIterationSplineLocation.WorldLocation - (DeviationRight * SplineLockProperties.AllowedHorizontalDeviation), -DeviationRight, Color = FLinearColor::Red)
			.Plane("Allowed Deviation Right", DebugFirstIterationSplineLocation.WorldLocation + (DeviationRight * SplineLockProperties.AllowedHorizontalDeviation), DeviationRight, Color = FLinearColor::Green)
		;

		const FVector UpVector = SplineLock::GetUpVector(PlaneLockType, CurrentSplinePosition, WorldUp);
		FVector MovementForward = SplineLock::GetMovementForward(PlaneLockType, CurrentSplinePosition, UpVector);

		FinalSectionLog.Section("Spline", 2)
			.Transform("Original SplineLocation", DebugFirstIterationSplineLocation.WorldTransform, 300, 10)
			.DirectionalArrow("Spline World Forward", DebugFirstIterationSplineLocation.WorldLocation, MovementForward * 300, 2, Color = FLinearColor::Yellow)
			.DirectionalArrow("Spline World Right", DebugFirstIterationSplineLocation.WorldLocation, DeviationRight * 300, 2, Color = FLinearColor::Green)
		;
	}
#endif
};