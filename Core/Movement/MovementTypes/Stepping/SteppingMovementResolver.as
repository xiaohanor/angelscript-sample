delegate void FSteppingMovementResolverHandleStepUpHitDelegate(FMovementHitResult& StepUpHit, bool&out bOutModifiedStepUpHit, bool&out bOutRetryStepUp);

/** 
 * Stepping movement is usually used by humanoids. This is the most advanced and most expensive resolver.
 * The stepping data can handle both normal velocity and horizontal velocity making it possible to maintain the movement speed on angled surfaces.
*/
class USteppingMovementResolver : UBaseMovementResolver
{
	default RequiredDataType = USteppingMovementData;
	private const USteppingMovementData SteppingData;
	
	bool bIterationIsSquished = false;
	float MovementSinceGroundedValidation = BIG_NUMBER;

	/**
	 * Allows modifying a StepUpHit before it is decided if we can step up or not.
	 * Specifically created for roll dragon shenanigans...
	 */
	FSteppingMovementResolverHandleStepUpHitDelegate HandleStepUpHitDelegate;

	bool bPerformSubStep = false;
	int BonusSubStepIterations = 0;
#if !RELEASE
	FString PerformSubStepReason = "";
#endif

	int VerticalDirection = 0;

	void PrepareResolver(const UBaseMovementData Movement) override
	{
		SteppingData = Cast<USteppingMovementData>(Movement);
		
		Super::PrepareResolver(Movement);

#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"PrepareResolver");
#endif

		IterationState.InitFromMovementData(SteppingData);
		IterationState.CurrentRotation = FinalizeRotation(IterationState.CurrentRotation, CurrentWorldUp);
		IterationTraceSettings.UpdateRotation(IterationState.CurrentRotation);

		bIterationIsSquished = false;
		MovementSinceGroundedValidation = BIG_NUMBER;

		bPerformSubStep = false;
		BonusSubStepIterations = 0;

		// Pick out the vertical plane for the vertical delta
		FVector VerticalPlane = CurrentWorldUp;
		{
			FMovementHitResult InitialGround = SteppingData.OriginalContacts.GroundContact;
			if(InitialGround.IsAnyGroundContact())
			{
				VerticalPlane = InitialGround.ImpactNormal;
			}
		}

		const FMovementDelta ImpulseDelta = IterationState.GetDelta(EMovementIterationDeltaStateType::Impulse);
		const FMovementDelta MovementDelta = IterationState.GetDelta(EMovementIterationDeltaStateType::Movement);

		const FMovementDelta VerticalImpulseDelta = ImpulseDelta.GetVerticalPart(CurrentWorldUp);
		const FMovementDelta VerticalMovementDelta = MovementDelta.GetVerticalPart(VerticalPlane);

		const FVector VerticalDelta = (VerticalImpulseDelta + VerticalMovementDelta).Delta;

		const float Dot = VerticalDelta.DotProduct(CurrentWorldUp);
		VerticalDirection = Math::Abs(Dot) > KINDA_SMALL_NUMBER ? int(Math::Sign(Dot)) : 0;
		if(VerticalDirection <= 0 && SteppingData.OriginalContacts.GroundContact.IsAnyGroundContact())
			VerticalDirection = 0;

#if !RELEASE
		ResolverTemporalLog.Value("VerticalDirection", VerticalDirection);
#endif

		// This requires us to sub step the movement so we detect an edge when it actually happens
		if(SteppingData.bAllowSubStep && CanPerformGroundTrace() && 
			(SteppingData.EdgeHandling == EMovementEdgeHandlingType::Stop || SteppingData.AlignWithImpactSettings.IsActive()))
		{
			bPerformSubStep = true;
			BonusSubStepIterations = SteppingData.MaxRedirectIterations;
			
#if !RELEASE
			FMovementDelta DebugDelta = GenerateIterationDelta();
			if(SteppingData.EdgeHandling == EMovementEdgeHandlingType::Stop)
				PerformSubStepReason = "EdgeHandling == Stop";
			else if(SteppingData.AlignWithImpactSettings.IsActive())
				PerformSubStepReason = "Align With Impact";
			DebugValidateMoveAmount(DebugDelta.Delta, SteppingData.ShapeSizeForMovement, BonusSubStepIterations, PerformSubStepReason);	
#endif
		}
	}

#if EDITOR
	void ResolveRerun() override
	{
		check(SteppingData != nullptr);

		Resolve();
		PostResolve();

		// Did the rerun succeed
		check(SteppingData.DebugFinalTransform.Equals(FTransform(IterationState.CurrentRotation, IterationState.CurrentLocation)));
	}
#endif

	void ResolveAndApplyMovementRequest(UHazeMovementComponent MovementComponent) override
	{
#if !RELEASE
		check(SteppingData != nullptr);
		check(!MovementComponent.IsApplyingInParallel());
#endif

		// In the editor, we add the rerun each movement frame
#if EDITOR
		USteppingMovementData RerunData = Cast<USteppingMovementData>(MovementComponent.AddRerunData(SteppingData, this));
#endif

		// Temporal log the first iteration state
#if !RELEASE
		MovementDebug::AddInitialDebugInfo(
			MovementComponent,
			SteppingData,
			this
		);
#endif
		
		Resolve();
		PostResolve();

		ApplyResolve(MovementComponent);
	
#if EDITOR
		// Update the final transform for rerun data so we can validate that
		if(RerunData != nullptr)
			RerunData.DebugFinalTransform = FTransform(IterationState.CurrentRotation, IterationState.CurrentLocation);
#endif

		// Temporal log the final state
#if !RELEASE
		MovementDebug::AddMovementResolvedState(
			MovementComponent,
			SteppingData,
			this,
			IterationState,
			SteppingData.IterationTime
		);
#endif
	}

	void StopResolving() override
	{
		Super::StopResolving();
		
		IterationState.PerformedMovementAlpha = 1.0;
	}

	UFUNCTION(BlueprintOverride)
	protected void ApplyResolve(UHazeMovementComponentBase MovementComponent) final
	{
		// Add all the data collected in the step
		MovementComponent.SetMovingStatus(true, SteppingData.StatusInstigator);
		auto MoveComp = Cast<UHazeMovementComponent>(MovementComponent);
		ApplyResolvedData(MoveComp);
		PostApplyResolvedData(MoveComp);
		MovementComponent.SetMovingStatus(false, SteppingData.StatusInstigator);
	}

	/** This function should add all the custom data collected in the internal movement data */
	protected void ApplyResolvedData(UHazeMovementComponent MovementComponent) override
	{
		Super::ApplyResolvedData(MovementComponent);

		// Update the physics state
		MovementComponent.SetContactsAndImpactsInternal(IterationState.PhysicsState, CurrentWorldUp, AccumulatedImpacts);

		// Change the velocity
		FVector FinalHorizontalVelocity = FVector::ZeroVector;
		FVector FinalVerticalVelocity = FVector::ZeroVector;
		GetResolvedVelocityToApply(FinalHorizontalVelocity, FinalVerticalVelocity);
		MovementComponent.SetVelocityInternal(FinalHorizontalVelocity, FinalVerticalVelocity);

		// Override the target facing rotation so if nothing new sets it, we have the current rotation
		MovementComponent.SetPendingTargetFacingRotationInternal(IterationState.CurrentRotation);

		// Stop falling
		if(MovementComponent.IsFalling())
		{
			if (!SteppingData.WantsToFall() || IterationState.PhysicsState.GroundContact.IsAnyGroundContact())
			{
				// Check blocking hit as a falling move that ends the frame on the ground should not end the frame considered falling
				MovementComponent.StopFalling(IterationState.CurrentLocation, MovementComponent.PreviousVelocity);
			}
		}
		// Start falling
		else
		{
			if (SteppingData.WantsToFall() && !IterationState.PhysicsState.GroundContact.IsAnyGroundContact())
			{
				if (CurrentWorldUp.DotProduct(FinalVerticalVelocity) < SMALL_NUMBER)
				{
					MovementComponent.StartFalling(IterationState.CurrentLocation);
				}
			}
		}

		// Finally, apply the actor location and rotation
		MovementComponent.HazeOwner.SetActorLocationAndRotation(IterationState.CurrentLocation, IterationState.CurrentRotation);

		if(IterationCount >= MaxRedirectIterations)
		{
			// We got stuck!
			// FB TODO: Make feature next project!
			MovementComponent.LastStuckFrame = Time::FrameNumber;
		}
	}

	protected void GetResolvedVelocityToApply(FVector& OutHorizontal, FVector& OutVertical) const
	{
		if(bIterationIsSquished)
			return;
		
		// If we add more delta states, we need to override this function
		check(IterationState.DeltaStates.Num() == 3);

		FMovementDelta MovementDelta = IterationState.GetDelta(EMovementIterationDeltaStateType::Movement);
		FMovementDelta HorizontalDelta = IterationState.GetDelta(EMovementIterationDeltaStateType::Horizontal);
		FMovementDelta Impulse = IterationState.GetDelta(EMovementIterationDeltaStateType::Impulse);

		OutHorizontal += MovementDelta.GetHorizontalPart(CurrentWorldUp).Velocity;
		OutHorizontal += HorizontalDelta.Velocity; // This velocity can also contain vertical information
		OutHorizontal += Impulse.GetHorizontalPart(CurrentWorldUp).Velocity;

		OutVertical += MovementDelta.GetVerticalPart(CurrentWorldUp).Velocity;
		OutVertical += Impulse.GetVerticalPart(CurrentWorldUp).Velocity;

		//OutVertical = GetTerminalVelocityClampedDelta(FMovementDelta(OutVertical * IterationTime, OutVertical)).Velocity;
	}

	/**
	 * The MAIN function. It should always be const to be able to call the rerun function.
	 * All non const data should be in the transient state.
	 * This will take the requested delta, and calculate the final delta,
	 * it also handles steps, depenetration etc.
	 */
	protected void Resolve() override
	{	
		if(HasMovementControl())
		{
			HandleIterationDeltaMovementOnControl();
		}
		else
		{
			HandleIterationDeltaMovementOnRemote();
		}

		// If the user has specified a custom final ground to be applied,
		// it is applied here.
		ApplyGroundOverride();
		
    }

	UFUNCTION(BlueprintOverride, Meta = (BlueprintThreadSafe))
	protected void ResolveParallel()
	{
		Resolve();
	}

	protected bool PrepareNextIteration() override
	{
		// Increase the iteration so we don't get stuck in a loop
		IterationCount++;

		Super::PrepareNextIteration();

#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"PrepareNextIteration");
#endif

		//StepUpSafetyOffset.Reset();

		// First iteration
		// We start with fixing the current ground
		// and applying the deltas upon that
		if (IterationCount == 1)
		{
			PrepareFirstIteration();
		}

		// Calculate the remaining delta to trace this iteration
		IterationState.DeltaToTrace = GenerateIterationDelta().Delta;
		const float DeltaSizeSq = IterationState.DeltaToTrace.SizeSquared();

		// This requires us to sub step the movement so we detect an edge when it actually happens
		if(bPerformSubStep && DeltaSizeSq > Math::Square(IterationTraceSettings.TraceLengthClamps.Min))
		{
			const FVector MaxDelta = IterationState.DeltaToTrace.GetClampedToMaxSize(SteppingData.ShapeSizeForMovement - SteppingData.SafetyDistance.X);
			IterationState.AlphaModifier = MaxDelta.SizeSquared() / DeltaSizeSq;
			IterationState.DeltaToTrace = MaxDelta;
		}

		// we have ended upp inside something and can't move anymore
		if(bIterationIsSquished)
			return false;

		if(IterationCount > SteppingData.MaxRedirectIterations)
			return false;

		if(IterationState.RemainingMovementAlpha < SMALL_NUMBER)
			return false;

		if(DeltaSizeSq <= Math::Square(IterationTraceSettings.TraceLengthClamps.Min))
		{
			IterationState.DeltaToTrace = FVector::ZeroVector;
			return false;
		}

		return true;
	}

	protected void PrepareFirstIteration()
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"PrepareFirstIteration");
#endif
		check(IterationCount == 1);
		
#if !RELEASE
		ResolverTemporalLog.Value("CanPerformGroundTrace", CanPerformGroundTrace());
		ResolverTemporalLog.Shape("Initial Location", IterationState.CurrentLocation, IterationTraceSettings.TraceShape, IterationTraceSettings.CollisionShapeOffset);
#endif

		if(!CanPerformGroundTrace())
			return;

		FMovementHitResult PreviousGround = IterationState.PhysicsState.GroundContact;
		FMovementHitResult& InitialGround = IterationState.PhysicsState.GroundContact;
		InitialGround = SteppingData.OriginalContacts.GroundContact;
		InitialGround.OverrideLocation(IterationState.CurrentLocation);

#if !RELEASE
		InitialGround.TraceTag = FHazeTraceTag(n"InitialGround");
		ResolverTemporalLog.MovementHit(InitialGround, IterationTraceSettings.TraceShape, IterationTraceSettings.CollisionShapeOffset);
#endif

		// We need to trace for the initial ground the first time
		// This usually happens when we change the size of the capsule
		// or we reset the actor
		if (SteppingData.bGenerateInitialGroundedStateFirstIteration)
		{
			float StepdownSize = GetStepDownSize();

			// If we used to be grounded, we increase the trace amount
			// to really try to find the ground again
			// FB TODO: This is really odd, and causes issues when the actor has valid ground, then moves in a sequence, then ends in air
			if(InitialGround.IsAnyGroundContact())
			{
				StepdownSize += SteppingData.ShapeSizeForMovement * 10;
			}

			FMovementResolverGroundTraceSettings GroundTraceSettings;
			GroundTraceSettings.bRedirectTraceIfInvalidGround = false;
			GroundTraceSettings.CustomTraceTag = n"InitialGroundTrace";
			InitialGround = QueryGroundShapeTrace(IterationState.CurrentLocation, -CurrentWorldUp * StepdownSize, GroundTraceSettings);
			
			if(InitialGround.IsAnyGroundContact())
			{
				ApplyGroundEdgeInformation(InitialGround);
				ApplyWalkOnEdgeGround(IterationState.CurrentLocation, InitialGround, PreviousGround);
			}

			ChangeGroundedState(IterationState, InitialGround, false);
			
			// Make sure we stand on the new ground on the control side
			// On the remote side, we must respect the replicated information
			if(InitialGround.IsValidBlockingHit())
			{
				IterationState.CurrentLocation = InitialGround.Location;
			}
		}
	
		if (InitialGround.IsAnyGroundContact())
		{
			if(!HandleStepUpOnMovementImpact(InitialGround, false) || SteppingData.EdgeHandling == EMovementEdgeHandlingType::Follow)
			{
				ApplyImpactOnDeltas(IterationState, InitialGround);
			}
		}
	}

	/**
	 * This function will change the pending delta moves
	 */
	void ApplyImpactOnDeltas(FMovementResolverState& State, FMovementHitResult Impact) const
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"ApplyImpactOnDeltas");
#endif

		// You should always be validating this before you reach this line
		// You have to have control over when to redirect and when to not do it
		if(!devEnsure(Impact.IsValidBlockingHit(), f"The component {Impact.Component} with actor {Impact.Actor} at location {Impact.ImpactPoint} is not valid for movement. BSPs are not supported any more."))
		{
			Debug::DrawDebugSphere(Impact.ImpactPoint, Math::Min(Impact.Component.Bounds.SphereRadius, 400), LineColor = FLinearColor::Red, Thickness = 6, Duration = 10);
		}
			
		const FMovementHitResult& GroundedState = State.PhysicsState.GroundContact;
		const bool bApplyRedirect = ShouldProjectMovementOnImpact(Impact);

#if !RELEASE
		ResolverTemporalLog.MovementDelta(f"Previous Sum", State.CurrentLocation, State.GetDelta(), InColor = FLinearColor::Red);
		for(auto It : State.DeltaStates)
			ResolverTemporalLog.MovementDelta(f"Previous {It.Key:n}", State.CurrentLocation, It.Value.ConvertToDelta(), InColor = FLinearColor::Red);
#endif

		for(auto It : State.DeltaStates)
		{
			const EMovementIterationDeltaStateType DeltaType = It.Key;
			FMovementDelta MovementDelta = It.Value.ConvertToDelta();

			if(MovementDelta.IsNearlyZero())
				continue;

			if(bApplyRedirect)
				MovementDelta = ProjectMovementUponImpact(State, MovementDelta, DeltaType, Impact, GroundedState);
			else
				MovementDelta = FMovementDelta();

			State.OverrideDelta(DeltaType, MovementDelta);
		}

#if !RELEASE
		ResolverTemporalLog.MovementDelta(f"New Sum", State.CurrentLocation, State.GetDelta(), InColor = FLinearColor::Green);
		for(auto It : State.DeltaStates)
			ResolverTemporalLog.MovementDelta(f"New {It.Key:n}", State.CurrentLocation, It.Value.ConvertToDelta(), InColor = FLinearColor::Green);
#endif
	}

	// By default, we always redirect. Can be overridden by custom resolvers
	protected bool ShouldProjectMovementOnImpact(FMovementHitResult Impact) const
	{
		if(Impact.IsWallImpact())
		{
			return SteppingData.bRedirectMovementOnWallImpacts;
		}

		return true;
	}

	/**
	 * Project a MovementDelta upon an impact.
	 * Consider overriding ProjectDeltaUpon[...] functions in child resolvers to change the behaviour instead of this function.
	 */
	FMovementDelta ProjectMovementUponImpact(FMovementResolverState& State, FMovementDelta DeltaState, EMovementIterationDeltaStateType DeltaStateType, FMovementHitResult Impact, FMovementHitResult GroundedState) const
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"ProjectMovementUponImpact");
#endif

		const bool bIsLeavingGround = IsLeavingGround();
		const bool bActorIsGrounded = !bIsLeavingGround && GroundedState.IsWalkableGroundContact();
		const bool bHitCanBeGround = !bIsLeavingGround && Impact.IsWalkableGroundContact();

		if(bActorIsGrounded)
		{
			if(bHitCanBeGround)
			{
				return ProjectDeltaUponFloorImpact(DeltaState, DeltaStateType, Impact, GroundedState);
			}
			else
			{
				return ProjectDeltaUponGroundedBlockingImpact(DeltaState, DeltaStateType, Impact, GroundedState);
			}
		}
		else
		{
			if(bHitCanBeGround)
			{
				return ProjectDeltaUponLandingImpact(DeltaState, DeltaStateType, Impact, GroundedState);
			}
			else
			{
				return ProjectDeltaUponGenericImpact(State, DeltaState, DeltaStateType, Impact, GroundedState);
			}
		}
	}

	/**
	 * Floor Impact
	 * We are grounded, and the impact is also ground.
	 */
	FMovementDelta ProjectDeltaUponFloorImpact(FMovementDelta DeltaState, EMovementIterationDeltaStateType DeltaStateType, FMovementHitResult Impact, FMovementHitResult GroundedState) const
	{
		FVector DeltaRedirectNormal = Impact.Normal;
	
		// If we are on edges, we use the impact normal instead to not get sucked down
		if(IsLeavingEdge(Impact))
		{
			if(!Impact.EdgeResult.OverrideRedirectNormal.IsNearlyZero())
				DeltaRedirectNormal = Impact.EdgeResult.OverrideRedirectNormal;
			else
				DeltaRedirectNormal = Impact.ImpactNormal;
		}
		// On low grounds, we need to follow the impact normal instead
		// So we don't lose velocity
		else if(Impact.IsStepupGroundContact() && !SteppingData.bSweepStep)
		{
			DeltaRedirectNormal = Impact.ImpactNormal;
		}

		FMovementDelta ConstrainedDeltaState = DeltaState;

		// On grounded impacts, we remove the vertical part
		// unless this is the horizontal movement since the vertical part might be following the ground
		// Its important that the vertical part is removed first, else that part will be redirected
		// to follow the ground on slopes
		if(DeltaStateType != EMovementIterationDeltaStateType::Horizontal)
		{
			ConstrainedDeltaState = ConstrainedDeltaState.GetHorizontalPart(CurrentWorldUp);
		}

		// We keep the velocity constrained to the actual impact normal
		// So the velocity don't flip weirdly when walking on edges
		// We redirect the delta without any loss.
		const FMovementDelta Velocity = ConstrainedDeltaState.SurfaceProject(GroundedState.ImpactNormal, CurrentWorldUp);
		const FMovementDelta Delta = ConstrainedDeltaState.SurfaceProject(DeltaRedirectNormal, CurrentWorldUp);
		return FMovementDelta(Delta.Delta, Velocity.Velocity);
	}

	/**
	 * Grounded Blocking Impact
	 * We are grounded, but hit unwalkable ground, a wall or ceiling.
	 */
	FMovementDelta ProjectDeltaUponGroundedBlockingImpact(FMovementDelta DeltaState, EMovementIterationDeltaStateType DeltaStateType, FMovementHitResult Impact, FMovementHitResult GroundedState) const
	{
		// On blocking hits, project the movement on the obstruction while following the grounding plane
		const FVector GroundNormal = GroundedState.Normal;
		const FVector ImpactNormal = Impact.Normal.GetImpactNormalProjectedAlongSurface(GroundNormal, CurrentWorldUp);

		const FVector Tangent = ImpactNormal.CrossProduct(GroundNormal).GetSafeNormal();
		const FVector ObstructionUpAlongGround = Tangent.CrossProduct(ImpactNormal).GetSafeNormal(ResultIfZero = GroundNormal);
		
		FMovementDelta ConstrainedDeltaState = DeltaState.SurfaceProject(ObstructionUpAlongGround, CurrentWorldUp);
		FMovementDelta ProjectedDelta = ConstrainedDeltaState.PlaneProject(ImpactNormal);
		return FMovementDelta(ProjectedDelta.Delta, ConstrainedDeltaState.Velocity.GetSafeNormal() * ProjectedDelta.Velocity.Size());	
	}

	/**
	 * Landing Impact
	 * We are airborne, but hit walkable ground.
	 */
	FMovementDelta ProjectDeltaUponLandingImpact(FMovementDelta DeltaState, EMovementIterationDeltaStateType DeltaStateType, FMovementHitResult Impact, FMovementHitResult GroundedState) const
	{
		FMovementDelta ConstrainedDeltaState = DeltaState;

		FVector LandingPlane = CurrentWorldUp;

		if(SteppingData.bProjectVelocityOnGroundNormalOnLanding)
		{
			LandingPlane = Impact.Normal;
		}

		// On landing impacts, we remove the vertical part
		// unless this is the horizontal movement since the vertical part might be following the ground
		// Its important that the vertical part is removed first, else that part will be redirected
		// to follow the ground on slopes
		if(DeltaStateType != EMovementIterationDeltaStateType::Horizontal)
		{
			ConstrainedDeltaState = ConstrainedDeltaState.GetHorizontalPart(LandingPlane);
		}

		ConstrainedDeltaState = ConstrainedDeltaState.PlaneProject(LandingPlane);
		ConstrainedDeltaState = ConstrainedDeltaState.SurfaceProject(Impact.Normal, CurrentWorldUp);
		return ConstrainedDeltaState;
	}

	/**
	 * Generic Impact
	 * We are airborne, and hit unwalkable ground, a wall or ceiling.
	 */
	FMovementDelta ProjectDeltaUponGenericImpact(FMovementResolverState& State, FMovementDelta DeltaState, EMovementIterationDeltaStateType DeltaStateType, FMovementHitResult Impact, FMovementHitResult GroundedState) const
	{
		FMovementDelta ConstrainedDeltaState = DeltaState.PlaneProject(Impact.Normal);

		bool bPreventRedirectingUpwards = false;

		if(!Impact.bIsWalkable)
			bPreventRedirectingUpwards = true;
		else if(Impact.IsCeilingImpact())
			bPreventRedirectingUpwards = true;

		if(bPreventRedirectingUpwards)
		{
			// For unwalkable surfaces, we do some extra handling to prevent getting stuck on unwalkable edges,
			// or moving too far up unwalkable slopes and walls.
			switch(DeltaStateType)
			{
				case EMovementIterationDeltaStateType::Movement:
				{
					// Don't project movement onto unwalkable impacts if it is not going into the surface
					if(DeltaState.Delta.DotProduct(Impact.Normal) > 0)
						ConstrainedDeltaState.Delta = DeltaState.Delta;

					if(DeltaState.Velocity.DotProduct(Impact.Normal) > 0)
						ConstrainedDeltaState.Velocity = DeltaState.Velocity;

					break;
				}

				case EMovementIterationDeltaStateType::Impulse:
					break;

				case EMovementIterationDeltaStateType::Horizontal:
				{
					// Only allow horizontal to redirect downwards, not upwards
					ConstrainedDeltaState = ConstrainedDeltaState.LimitToNormal(-CurrentWorldUp);

					if(SteppingData.bWasStuckLastFrame)
					{
						// If we are stuck, add a little delta to attempt to un-stuck us
						ConstrainedDeltaState.Delta += Impact.Normal;

						// Also clamp the horizontal velocity, so that it doesn't accumulate over time
						// FB TODO: Better solution next game?
						ConstrainedDeltaState.Velocity = ConstrainedDeltaState.Velocity.GetClampedToMaxSize(600);
					}
					break;
				}

				case EMovementIterationDeltaStateType::Sum:
					break;
			}
		}

		// If we used to have velocity going into the wall, but the wall impact kills all velocity
		// we keep a small portion so we will continue going into the wall the next time;
		FVector& ConstrainedVelocity = ConstrainedDeltaState.Velocity;
		if(!DeltaState.Velocity.IsNearlyZero())
			ConstrainedVelocity = ConstrainedDeltaState.Velocity.GetClampedToSize(1.0, ConstrainedDeltaState.Velocity.Size()); 

		return ConstrainedDeltaState;
	}

	/**
	 * A delta trace with an impact should be processed trough this function
	 * It will take care of steps, and new grounds.
	 * Applies the pending movement
	 */
	protected void HandleIterationDeltaMovementImpact(FMovementHitResult& MovementHit)
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"HandleIterationDeltaMovementImpact");
#endif

		switch(MovementHit.Type)
		{
			case EMovementImpactType::Ground:
				HandleIterationDeltaMovementGroundImpact(MovementHit);
				break;

			case EMovementImpactType::Wall:
				HandleIterationDeltaMovementWallImpact(MovementHit);
				break;

			case EMovementImpactType::Ceiling:
				HandleIterationDeltaMovementCeilingImpact(MovementHit);
				break;

			default:
				check(false, "Invalid MovementHit!");
				break;
		}
	}

	/**
	 * 
	 */
	protected void HandleIterationDeltaMovementGroundImpact(FMovementHitResult& MovementHit)
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"HandleIterationDeltaMovementGroundImpact");
#endif

		check(MovementHit.Type == EMovementImpactType::Ground);

		if(HandleMovementImpactInternal(MovementHit, EMovementResolverAnyShapeTraceImpactType::Iteration))
			return;

		const bool bIsLeavingGround = IsLeavingGround();
		const bool bWasGrounded = !bIsLeavingGround && IterationState.PhysicsState.GroundContact.IsWalkableGroundContact();
		const bool bHitCanBeGround = !bIsLeavingGround && MovementHit.IsWalkableGroundContact();

		const bool bIsLandingImpact = !bWasGrounded && bHitCanBeGround;

		if(SteppingData.LandOnUnstableEdgeHandling != ESteppingLandOnUnstableEdgeHandling::None && bIsLandingImpact)
		{
			// We landed on something, and we need to know if the new ground is an unstable edge or not
			TryHandleLandOnUnstableEdge(MovementHit, IterationState);
			if(!MovementHit.IsAnyGroundContact())
			{
				ChangeGroundedState(IterationState, MovementHit);
				return;
			}
		}

		TryAlignWorldUpWithGround(MovementHit);
		ApplyImpactOnDeltas(IterationState, MovementHit);
		ChangeGroundedState(IterationState, MovementHit);

		IterationState.ApplyMovement(MovementHit.Time, MovementHit.Location);

		// During sweeping steps, the redirect for some reason,
		// sometimes makes us stuck into on the edge, performing the same trace
		// over and over again. So we need to move the actor up a lite bit to get over
		// any edge.
		if(GetStepUpSize() > 0 && SteppingData.bSweepStep)
			IterationState.CurrentLocation += IterationState.WorldUp * 0.5;
	}

	/**
	 * If we don't have any synced information
	 * we handle the wall impact
	 * Synced information should always go through ceilings
	 */
	protected void HandleIterationDeltaMovementWallImpact(FMovementHitResult& MovementHit)
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"HandleIterationDeltaMovementWallImpact");
#endif

		check(MovementHit.Type == EMovementImpactType::Wall);
		
		if(SteppingData.bHasSyncedLocationInfo)
		{
			// Replicated move
			// If this is not a low wall, its a real wall
			// and we log the impact
			// but never redirect against it
			if(!MovementHit.IsStepupGroundContact())
				IterationState.PhysicsState.WallContact = MovementHit;

			HandleIterationDeltaMovementWithoutImpact();	
			return;	
		}

		// We always need to update the ground where we hit the wall first
		// so we align correctly with the wall impact
		FMovementHitResult GroundAtWallImpact;
		if(CanPerformGroundTrace() && IterationState.PhysicsState.GroundContact.IsAnyGroundContact())
		{
			// When we hit a wall, we usually need to validate
			// the ground at the wall.
			// But the wall might be a very small wall under the shape size
			// so we then need to use the normal instead to validate the impact
			FMovementResolverGroundTraceSettings GroundTraceSettings;
			GroundTraceSettings.NormalForImpactTypeGenerationType = EMovementResolverNormalForImpactTypeGenerationType::Normal;
			GroundTraceSettings.bRedirectTraceIfInvalidGround = true;
			GroundTraceSettings.CustomTraceTag = n"GroundTraceAtWall";
			GroundAtWallImpact = QueryGroundShapeTrace(MovementHit.Location, -CurrentWorldUp * GetStepDownSize(), GroundTraceSettings);

			if(GroundAtWallImpact.IsValidBlockingHit() && HandleMovementImpactInternal(GroundAtWallImpact, EMovementResolverAnyShapeTraceImpactType::GroundAtWall))
				return;

			if(GroundAtWallImpact.IsAnyGroundContact())
				ApplyWalkOnEdgeGround(IterationState.CurrentLocation, GroundAtWallImpact, IterationState.PhysicsState.GroundContact);

			// Update the grounded state before we perform the wall impact
			ChangeGroundedState(IterationState, GroundAtWallImpact, false);
		}

		// Before we do anything else, first, we check if we can stepup on the wall
		// But we only do this if we the wall was first detected as a wall.
		// If the wall was found through sub iterations, it is always going to be an angled wall
		if(HandleStepUpOnMovementImpact(MovementHit, true))
		{
			// Since we could stepup,
			// we are now at a new height and can perform a new iteration
			return;
		}
		else
		{
			// Since no step up occurred, we actually hit a wall, and must now handle the movement impact
			// FB TODO: Why is step up after GroundAtWall trace?
			if(MovementHit.IsValidBlockingHit() && HandleMovementImpactInternal(MovementHit, EMovementResolverAnyShapeTraceImpactType::Iteration))
				return;
		}

		IterationState.ApplyMovement(MovementHit.Time, MovementHit.Location);
		IterationState.PhysicsState.WallContact = MovementHit;
		ApplyImpactOnDeltas(IterationState, MovementHit);

		// Even if we hit a wall, if we are traveling upwards, this counts as a ceiling if we are hitting the edge of the capsule
		if(IsLeavingGround())
		{
			const EMovementImpactType ImpactTypeUsingNormal = GetImpactTypeFromHit(MovementHit.InternalHitResult, CurrentWorldUp, MovementHit.Normal);
			if(ImpactTypeUsingNormal == EMovementImpactType::Ceiling)
			{
				IterationState.PhysicsState.CeilingContact = MovementHit;
				IterationState.PhysicsState.CeilingContact.Type = EMovementImpactType::Ceiling;
			}
		}
	}

	/**
	 * If we don't have any synced information, we handle the ceiling impact
	 * Synced information should always go through ceilings
	 */
	protected void HandleIterationDeltaMovementCeilingImpact(FMovementHitResult& MovementHit)
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"HandleIterationDeltaMovementCeilingImpact");
#endif

		check(MovementHit.Type == EMovementImpactType::Ceiling);

		if(SteppingData.bHasSyncedLocationInfo)
		{
			// Replicated move
			IterationState.PhysicsState.CeilingContact = MovementHit;
			HandleIterationDeltaMovementWithoutImpact();
			return;
		}

		if(HandleMovementImpactInternal(MovementHit, EMovementResolverAnyShapeTraceImpactType::Iteration))
			return;

		ApplyImpactOnDeltas(IterationState, MovementHit);
		IterationState.PhysicsState.CeilingContact = MovementHit;
		IterationState.ApplyMovement(MovementHit.Time, MovementHit.Location);
	}

	/**
	 * No impact to process.
	 * Applies the pending movement
	 */
	protected void HandleIterationDeltaMovementWithoutImpact()
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"HandleIterationDeltaMovementWithoutImpact");
#endif

		const FVector PendingLocation = GetUnhinderedPendingLocation();

#if !RELEASE
		ResolverTemporalLog.Shape("Pending Location", PendingLocation, IterationTraceSettings.TraceShape, IterationTraceSettings.CollisionShapeOffset);
#endif

		// Handle stop movement at edges
		// This can only be applied on the control side
		// since the edge might not be in the same location
		if(SteppingData.EdgeHandling == EMovementEdgeHandlingType::Stop
			&& CanPerformGroundTrace()
			&& IterationState.PhysicsState.GroundContact.IsAnyGroundContact())
		{
			FMovementResolverGroundTraceSettings GroundTraceSettings;
			GroundTraceSettings.bRedirectTraceIfInvalidGround = true;
			FMovementHitResult PendingGround = QueryGroundShapeTrace(PendingLocation, -CurrentWorldUp * GetStepDownSize(), GroundTraceSettings);

			if(PendingGround.IsValidBlockingHit() && HandleMovementImpactInternal(PendingGround, EMovementResolverAnyShapeTraceImpactType::Ground))
				return;

			ApplyGroundEdgeInformation(PendingGround);
	
			IterationState.ApplyMovement(1, PendingLocation);

#if !RELEASE
			ResolverTemporalLog.Value("EdgeHandling::Stop", "Valid current ground, apply the pending location.");
#endif
			
			if(PendingGround.IsWalkableGroundContact())
			{
				TryAlignWorldUpWithGround(PendingGround);
				ApplyImpactOnDeltas(IterationState, PendingGround);
			}

			if(PendingGround.IsAnyGroundContact())
			{
				const FMovementHitResult PreviousGround = IterationState.PhysicsState.GroundContact;
				ApplyWalkOnEdgeGround(IterationState.CurrentLocation, PendingGround, PreviousGround);
			}

			ChangeGroundedState(IterationState, PendingGround);
		}
		// By default, we apply the entire move
		// and update the grounded state
		else
		{
			IterationState.ApplyMovement(1, PendingLocation);
			
			if(CanPerformGroundTrace())
			{
				FMovementResolverGroundTraceSettings GroundTraceSettings;
				GroundTraceSettings.NormalForImpactTypeGenerationType = EMovementResolverNormalForImpactTypeGenerationType::ImpactNormal;
				GroundTraceSettings.bRedirectTraceIfInvalidGround = true;
				FMovementHitResult PendingGround = QueryGroundShapeTrace(PendingLocation, -CurrentWorldUp * GetStepDownSize(), GroundTraceSettings);

				if(PendingGround.IsValidBlockingHit() && HandleMovementImpactInternal(PendingGround, EMovementResolverAnyShapeTraceImpactType::Ground))
					return;

				// We landed on something, and we need to know if the new ground is an unstable edge or not
				TryHandleLandOnUnstableEdge(PendingGround, IterationState);

				if(!PendingGround.IsAnyGroundContact())
				{
					ChangeGroundedState(IterationState, PendingGround);
					return;
				}

				TryAlignWorldUpWithGround(PendingGround);

				if(PendingGround.IsAnyGroundContact())
				{	
					ApplyImpactOnDeltas(IterationState, PendingGround);

					const FMovementHitResult PreviousGround = IterationState.PhysicsState.GroundContact;
					ApplyWalkOnEdgeGround(IterationState.CurrentLocation, PendingGround, PreviousGround);
				}

				ChangeGroundedState(IterationState, PendingGround);
			}
		}
	}

	bool IsCapsuleBottomFlat() const
	{
		switch(SteppingData.BottomOfCapsuleMode)
		{
			case ESteppingMovementBottomOfCapsuleMode::Rounded:
				return false;

			case ESteppingMovementBottomOfCapsuleMode::Flat:
				return true;

			case ESteppingMovementBottomOfCapsuleMode::FlatExceptWhenGroundUnder:
				return true;
		}
	}

	/**
	 * Determine if the edge on PendingGround should be extended, followed or if she should simply move past it.
	 * @param bFollowDown Should we move down over the edge? This means there is ground beneath the edge which we want to reach.
	 * @return True if the ground should be extended.
	 */
	protected bool ShouldExtendGroundEdge(FMovementHitResult PreviousGround, FMovementHitResult& PendingGround, bool&out bFollowDown) const
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"ShouldExtendGroundEdge");
#endif

		if(!PendingGround.IsWalkableGroundContact())
			return false;

		if(!PreviousGround.IsWalkableGroundContact())
			return false;

		// We only support Sphere and Aligned capsule Capsule
		switch(GetMovementShapeType())
		{
			case EMovementShapeType::Invalid:
				return false;
			case EMovementShapeType::Sphere:
				break;
			case EMovementShapeType::AlignedCapsule:
				break;
			case EMovementShapeType::FlippedCapsule:
				return false;
			case EMovementShapeType::NonAlignedCapsule:
				return false;
			case EMovementShapeType::Box:
				return false;
		}

		switch(SteppingData.BottomOfCapsuleMode)
		{
			// Rounded bottom shape should never extend ground
			case ESteppingMovementBottomOfCapsuleMode::Rounded:
				return false;

			// Flat bottom shape should always extend ground
			case ESteppingMovementBottomOfCapsuleMode::Flat:
			{
				ApplyGroundEdgeInformation(PendingGround);

				if(SteppingData.bOnlyFlatBottomOfCapsuleIfLeavingEdge)
				{
					// Only extend the ground if we are actually on an edge, and we are leaving it
					if(!IsLeavingEdge(PendingGround))
						return false;
				}
				else
				{
					// Only extend the ground if we are actually on an edge
					if(!PendingGround.IsOnAnEdge())
						return false;
				}

				return true;
			}

			case ESteppingMovementBottomOfCapsuleMode::FlatExceptWhenGroundUnder:
			{
				ApplyGroundEdgeInformation(PendingGround);

				if(SteppingData.bOnlyFlatBottomOfCapsuleIfLeavingEdge)
				{
					// Only extend the ground if we are actually on an edge, and we are leaving it
					if(!IsLeavingEdge(PendingGround))
						return false;
				}
				else
				{
					// Only extend the ground if we are actually on an edge
					if(!PendingGround.IsOnAnEdge())
						return false;
				}

				/**
				 * FB TODO: This should probably be combined with the validation sweep in ApplyGroundEdgeInformation
				 */
				// Start with our location on the edge plane
				const FVector BottomOfShapeLocation = IterationState.ConvertLocationToShapeBottomLocation(PendingGround.ImpactPoint, IterationTraceSettings);
				FVector TraceFrom = BottomOfShapeLocation.PointPlaneProject(PendingGround.ImpactPoint, PendingGround.EdgeResult.EdgeNormal);
				TraceFrom = IterationState.ConvertShapeBottomLocationToCurrentLocation(TraceFrom, IterationTraceSettings);

				// Move out horizontally by the shape size and safety distance
				const FVector HorizontalEdgeNormal = PendingGround.EdgeResult.EdgeNormal.VectorPlaneProject(CurrentWorldUp).GetSafeNormal();
				TraceFrom += HorizontalEdgeNormal * (SteppingData.ShapeSizeForMovement + SteppingData.SafetyDistance.X);

				// Move up vertically by the safety distance
				TraceFrom += CurrentWorldUp * SteppingData.SafetyDistance.Y;
				
				// Do a step down trace
				FVector TraceDelta = CurrentWorldUp * -GetStepDownSize();

				FMovementResolverGroundTraceSettings GroundTraceSettings;
				GroundTraceSettings.CustomTraceTag = n"PastEdgeGroundTrace";
				GroundTraceSettings.NormalForImpactTypeGenerationType = EMovementResolverNormalForImpactTypeGenerationType::Normal;
				GroundTraceSettings.bRedirectTraceIfInvalidGround = true;
				GroundTraceSettings.bResolveStartPenetrating = false;

				// Trace down to see if there's ground under the edge
                // If there is, we want to smoothly move down to it
                // If not, we want to extend the ground
				const FMovementHitResult PastEdgeGroundTrace = QueryGroundShapeTrace(TraceFrom, TraceDelta, CurrentWorldUp, GroundTraceSettings);

				if(PastEdgeGroundTrace.IsWalkableGroundContact())
				{
					bFollowDown = true;
					return false;
				}

				// We will not follow down, and instead extend the ground to walk on it.
				return true;
			}
		}
	}

	/**
	 * When moving along an edge, we may want to extend the edge ground out to pretend the bottom of our capsule is flat
	 */
	protected void ApplyWalkOnEdgeGround(FVector& CurrentLocation, FMovementHitResult& PendingGround, FMovementHitResult PreviousGround)
	{
		const FVector PreviousLocation = IterationState.CurrentLocation;

#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"ApplyWalkOnEdgeGround");
		ResolverTemporalLog.Shape("Previous Location", PreviousLocation, IterationTraceSettings.TraceShape, IterationTraceSettings.CollisionShapeOffset, FLinearColor::Yellow);
#endif
		if(!ensure(PendingGround.IsAnyGroundContact()))
			return;

		// When walking over an edge, we may want to extend it to
		// pretend that the bottom of our capsule is flat
		bool bFollowDown = false;
		if(ShouldExtendGroundEdge(PreviousGround, PendingGround, bFollowDown))
		{
			bool bStoppedAtEdge = false;

			if(SteppingData.EdgeHandling == EMovementEdgeHandlingType::Stop)
				bStoppedAtEdge = ApplyStopAtEdge(CurrentLocation, IterationState, PendingGround);

			FVector BottomCapCenter = IterationState.GetShapeBottomCapCenterLocation(IterationTraceSettings, SteppingData.ShapeSizeForMovement);

			// Project the bottom cap center of the shape onto the extended edge ground plane
			const FVector BottomOfShapeOnEdgeGroundPlane = BottomCapCenter.PointPlaneProject(PendingGround.ImpactPoint, PendingGround.EdgeResult.GroundNormal);

			// Offset the projected point out to place it where the center should be
			BottomCapCenter = BottomOfShapeOnEdgeGroundPlane + PendingGround.EdgeResult.GroundNormal * SteppingData.ShapeSizeForMovement;

			// Convert the center of the bottom cap location to the current location
			FVector CurrentLocationOnEdgeGroundPlane = IterationState.ConvertShapeBottomCapCenterLocationToCurrentLocation(BottomCapCenter, IterationTraceSettings, SteppingData.ShapeSizeForMovement);

			// Apply the safety distance to not collide with the edge
			CurrentLocationOnEdgeGroundPlane += PendingGround.EdgeResult.GroundNormal * SteppingData.SafetyDistance.Y;

			// Place this ground hit at the location on the edge plane
			PendingGround.OverrideLocation(CurrentLocationOnEdgeGroundPlane);

			// Override the normals so that subsequent movement/capabilities thinks the ground is flat instead of curving down.
			PendingGround.OverrideNormals(PendingGround.EdgeResult.GroundNormal, PendingGround.ImpactNormal);

			// Override the redirect normal to be the edge plane
			PendingGround.EdgeResult.OverrideRedirectNormal = PendingGround.ImpactNormal;

			// If we are above the plane, put us on it
			const FPlane EdgeGroundPlane(PendingGround.ImpactPoint, PendingGround.EdgeResult.GroundNormal);
			const bool bIsAboveGroundPlane = EdgeGroundPlane.PlaneDot(CurrentLocationOnEdgeGroundPlane) > 0;

			const FVector Delta = IterationState.GetDelta().Delta;
			const bool bIsMovingIntoGroundPlane = Delta.DotProduct(PendingGround.EdgeResult.GroundNormal) < 0;
			//const bool bIsMovingTowardsGround = Delta.DotProduct(PendingGround.EdgeResult.EdgeNormal) < 0;

			if(bIsAboveGroundPlane || bIsMovingIntoGroundPlane || bStoppedAtEdge)
			{
				// If we are above the plane, trying to move through it, or stopped at the edge, place us on the plane
				CurrentLocation = CurrentLocationOnEdgeGroundPlane;
			}
			// else if(!bIsAboveGroundPlane && bIsMovingTowardsGround && !CurrentLocation.Equals(CurrentLocationOnEdgeGroundPlane))
			// {
			// 	// If we are below the plane and trying to move into it, move us up towards the plane
			// 	const float MoveDistance = Delta.Size();
			// 	const float TotalMoveDistance = CurrentLocation.Distance(CurrentLocationOnEdgeGroundPlane);
			// 	const float Alpha = Math::Saturate(MoveDistance / TotalMoveDistance);
			// 	CurrentLocation = Math::Lerp(CurrentLocation, CurrentLocationOnEdgeGroundPlane, Alpha);
			// }

#if !RELEASE
			ResolverTemporalLog.OverwriteMovementHit(PendingGround);
			ResolverTemporalLog.Value("Should Extend Ground Edge", true);
			ResolverTemporalLog.Plane("Ground Edge Plane", PendingGround.ImpactPoint, EdgeGroundPlane.Normal);
			ResolverTemporalLog.Shape("CurrentLocationOnEdgeGroundPlane (Shape)", CurrentLocationOnEdgeGroundPlane, IterationTraceSettings.TraceShape, IterationTraceSettings.CollisionShapeOffset, InColor = FLinearColor::Green);
			ResolverTemporalLog.Point("CurrentLocationOnEdgeGroundPlane (Point)", CurrentLocationOnEdgeGroundPlane, InColor = FLinearColor::Green);
			ResolverTemporalLog.Shape("Current Location", CurrentLocation, IterationTraceSettings.TraceShape, IterationTraceSettings.CollisionShapeOffset, InColor = FLinearColor::Green);
#endif
		}
		else
		{
			// If we are currently grounded, but should not extend the ground, we want to follow the ground location when moving over edges
			if(!bFollowDown
				&& PreviousGround.IsWalkableGroundContact()
				&& (!PreviousGround.IsOnAnEdge() || PreviousGround.EdgeResult.IsMovingPastEdge())
				&& PendingGround.IsWalkableGroundContact())
				bFollowDown = true;

			if(bFollowDown)
			{
				CurrentLocation = PendingGround.Location;

				// If we follow the edge down, it can't possibly be unstable
				PendingGround.EdgeResult.UnstableDistance = -1;
			}
			else
			{
				if(PendingGround.EdgeResult.IsEdge() && SteppingData.EdgeHandling == EMovementEdgeHandlingType::Stop)
					ApplyStopAtEdge(CurrentLocation, IterationState, PendingGround);
			}

#if !RELEASE
			ResolverTemporalLog.Value("ShouldExtendGroundEdge", false);
			ResolverTemporalLog.Value("bFollowDown", bFollowDown);
			ResolverTemporalLog.Shape("Current Location", CurrentLocation, IterationTraceSettings.TraceShape, IterationTraceSettings.CollisionShapeOffset, InColor = FLinearColor::Green);
#endif		
		}

		// No need to validate when following down, since we are moving onto a sweep we have already performed
		if(!bFollowDown)
		{
			const FVector Delta = (CurrentLocation - PreviousLocation);
			if(!Delta.IsNearlyZero())
			{
				// We only move horizontally, because we might otherwise hit the outside of the edge, which would be bad
				const FVector PreviousLocationOnGroundPlane = PreviousLocation.PointPlaneProject(CurrentLocation, PendingGround.EdgeResult.GroundNormal);
				const FVector HorizontalDelta = CurrentLocation - PreviousLocationOnGroundPlane;

				if(!HorizontalDelta.IsNearlyZero())
				{
					// Validate that we can actually move to this new location
					const FMovementHitResult Hit = QueryShapeTrace(IterationTraceSettings, PreviousLocationOnGroundPlane, HorizontalDelta, CurrentWorldUp, GenerateTraceTag(n"ValidationSweep", n"ApplyWalkOnEdgeGround"));

					if(Hit.IsValidBlockingHit())
					{
						CurrentLocation = Hit.Location;
					}
				}
			}
		}
	}

	/**
	 * Attempt to put the CurrentLocation on the edge plane of PendingGround.
	 * Only call if EdgeHandling is Stop.
	 * @return True if we stopped at the edge.
	 */
	protected bool ApplyStopAtEdge(FVector& CurrentLocation, FMovementResolverState& State, FMovementHitResult PendingGround) const
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope ApplyStopAtEdgeScope(this, n"ApplyStopAtEdge");
#endif

#if EDITOR
		MovementCheck(PendingGround.EdgeResult.IsValidEdge());
#endif

		if(!MovementEnsure(SteppingData.EdgeHandling == EMovementEdgeHandlingType::Stop))
			return false;

		if(!PendingGround.EdgeResult.IsMovingPastEdge())
			return false;

		float UnstableDistance = 0;
		if(PendingGround.EdgeResult.UnstableDistance > 0)
		{
			UnstableDistance = PendingGround.EdgeResult.UnstableDistance;

			// Never allow the UnstableDistance to go below the horizontal safety distance,
			// this could cause us to not find the edge next frame while  walking into it
			UnstableDistance = Math::Max(UnstableDistance, SteppingData.SafetyDistance.X);
		}
		
		// We try to use the ground normal to keep the edge normal pointing towards our pending location
		FVector EdgeNormal = PendingGround.Normal.VectorPlaneProject(PendingGround.EdgeResult.GroundNormal).GetSafeNormal();

		// If that for some reason does not exist, use the actual edge normal, which can yield jittery results on complex edges
		if(EdgeNormal.IsNearlyZero())
			EdgeNormal = PendingGround.EdgeResult.EdgeNormal;

		// Always flatten the edge normal
		//EdgeNormal = EdgeNormal.VectorPlaneProject(CurrentWorldUp).GetSafeNormal();

		const FVector UnstableEdgeLocation = PendingGround.ImpactPoint + (EdgeNormal * UnstableDistance);

		check(!EdgeNormal.IsNearlyZero());
		const FPlane UnstableEdgePlane = FPlane(UnstableEdgeLocation, EdgeNormal);
		const float PreviousDistanceFromEdge = UnstableEdgePlane.PlaneDot(SteppingData.OriginalActorTransform.Location);
		const float PendingDistanceFromEdge = UnstableEdgePlane.PlaneDot(CurrentLocation);

#if !RELEASE
		ResolverTemporalLog.Plane("Unstable Edge Plane", UnstableEdgeLocation, EdgeNormal);
		ResolverTemporalLog.Value("Previous Distance From Edge", PreviousDistanceFromEdge);
		ResolverTemporalLog.Value("Pending Distance From Edge", PendingDistanceFromEdge);
#endif

		if(PendingDistanceFromEdge < 0)
		{
			// No need to stop at the edge, we haven't moved past it
			return false;
		}
#if !RELEASE
		ResolverTemporalLog.Shape("Pre StopAtEdge", CurrentLocation, IterationTraceSettings.TraceShape, IterationTraceSettings.CollisionShapeOffset, InColor = FLinearColor::Green);
#endif

		const FVector PreviousLocation = State.GetPreviousIterationLocation();
		float32 Time = 0;
		FVector Intersection = FVector::ZeroVector;
		if(Math::LinePlaneIntersection(PreviousLocation, CurrentLocation, UnstableEdgePlane, Time, Intersection))
		{
			// We have moved through the edge
			// Stop us at the intersection
			CurrentLocation = Intersection;

			for(auto It : State.DeltaStates)
			{
				FMovementDelta MovementDelta = It.Value.ConvertToDelta();
				if(MovementDelta.IsNearlyZero())
					continue;

				FMovementDelta DeltaAlongEdgePlane = MovementDelta.PlaneProject(EdgeNormal);

				// Multiply the delta going into the edge plane with the time to slow us down the appropriate amount
				FMovementDelta DeltaIntoEdge = MovementDelta.ProjectOntoNormal(EdgeNormal);
				DeltaIntoEdge *= Time;

				MovementDelta = DeltaAlongEdgePlane + DeltaIntoEdge;
				State.OverrideDelta(It.Key, MovementDelta);
			}
		}
		else
		{
			// We have already moved past the edge
			// Just constraint us to be along the plane, but not on the plane

			FVector Delta = CurrentLocation - PreviousLocation;
			Delta = Delta.VectorPlaneProject(EdgeNormal);
			CurrentLocation = PreviousLocation + Delta;

			for(auto It : State.DeltaStates)
			{
				FMovementDelta MovementDelta = It.Value.ConvertToDelta();
				if(MovementDelta.IsNearlyZero())
					continue;

				// Clamp any deltas moving into the edge direction
				if(MovementDelta.Delta.DotProduct(EdgeNormal) > 0)
					MovementDelta.Delta = MovementDelta.Delta.VectorPlaneProject(EdgeNormal);

				if(MovementDelta.Velocity.DotProduct(EdgeNormal) > 0)
					MovementDelta.Velocity = MovementDelta.Velocity.VectorPlaneProject(EdgeNormal);

				State.OverrideDelta(It.Key, MovementDelta);
			}
		}

#if !RELEASE
		ResolverTemporalLog.Shape("Post StopAtEdge", CurrentLocation, IterationTraceSettings.TraceShape, IterationTraceSettings.CollisionShapeOffset, InColor = FLinearColor::Red);
#endif

		return true;
	}

	protected void HandleIterationDeltaMovementOnControl()
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"HandleIterationDeltaMovementOnControl");
#endif

		// Make sure all the iteration data is setup for the first run
		RunPrepareNextIteration();

		// The main loop
		// we clear the current impacts the first iteration so we always start out fresh
		while(true)
		{   
			if (!IterationState.DeltaToTrace.IsNearlyZero())
			{	
				// Generate the iteration hit
				FMovementHitResult IterationHit;
				GenerateIterationHit(SteppingData, IterationState, IterationHit);

				// BAD iteration. We could not get out and are now stuck
				if(IterationHit.bStartPenetrating)
				{
					bIterationIsSquished = true;
					break;
				}

				// We have hit something and need to handle the impact.
				else if(IterationHit.bBlockingHit)
				{		
					HandleIterationDeltaMovementImpact(IterationHit);	
				}

				// This was a free trace so we can move the entire requested delta
				else
				{
					HandleIterationDeltaMovementWithoutImpact();
				}
			}

			// We have no delta so we know that we will not hit something new
			else
			{
				HandleIterationDeltaMovementWithoutImpact();
			}	

			if(!RunPrepareNextIteration())
				break;  // We are done
		}
	}

	protected void HandleIterationDeltaMovementOnRemote()
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"HandleIterationDeltaMovementOnRemote");
#endif

		// On the remote side, we just move to the wanted location
		IterationState.DeltaToTrace = GenerateIterationDelta().Delta;
		FVector PendingLocation = IterationState.CurrentLocation + IterationState.DeltaToTrace;
		
		// But we also try to find the ground so the remote side will have the status of grounded or airborne.
		if(CanPerformGroundTrace())
		{
			FMovementResolverGroundTraceSettings Settings;
			Settings.NormalForImpactTypeGenerationType = EMovementResolverNormalForImpactTypeGenerationType::ImpactNormal;
			Settings.bRedirectTraceIfInvalidGround = false;

			// We trace for the ground, using a sphere with the same amount as the capsule radius.
			// Since the networked replicated position might place us inside a shape,
			// We start the trace a bit higher up, but still inside the original shape,
			// making it possible to find the correct ground position.
			FHazeMovementTraceSettings TraceSettings = IterationTraceSettings;
			TraceSettings.OverrideTraceShape(FHazeTraceShape::MakeSphere(SteppingData.ShapeSizeForMovement));
			
			// Since the capsule might be offset from the feet location,
			// we need to add that offset into the trace length
			float TraceLength = GetStepDownSize();

			// This is a grounded movement so we need to make sure that we find the ground.
			// So we add some extra trace distance in case the stepdown is not set correctly
			if(ShouldValidateRemoteSideGroundPosition())
				TraceLength += SteppingData.ShapeSizeForMovement;

			FMovementHitResult PendingGround = QueryGroundShapeTrace(
				TraceSettings,
				PendingLocation, 
				-CurrentWorldUp * TraceLength, 
				CurrentWorldUp,
				Settings);

			if(PendingGround.IsAnyGroundContact())
			{	
				const FMovementHitResult PreviousGround = IterationState.PhysicsState.GroundContact;
				ApplyWalkOnEdgeGround(IterationState.CurrentLocation, PendingGround, PreviousGround);
			}

			IterationState.PhysicsState.GroundContact = PendingGround;

			// Use the impact for remote impact callbacks
			AccumulatedImpacts.AddImpact(IterationState.PhysicsState.GroundContact);
		}

		IterationState.ApplyMovement(1, PendingLocation);
	}

	protected bool HandleStepUpOnMovementImpact(FMovementHitResult& OutIterationHit, bool bApplyMovement)
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"HandleStepUpOnMovementImpact");
#endif

		if(IsLeavingGround())
			return false;

		if(!IterationState.PhysicsState.GroundContact.IsAnyGroundContact())
			return false;
		
		//FMovementHitResult IterationHit = OutIterationHit;
		if(!OutIterationHit.bIsWalkable && !SteppingData.bCanTriggerStepUpOnUnwalkableSurface)
			return false;
		
		FMovementHitResult StepUpHit;
		if(!GetLowGroundStepUpImpact(OutIterationHit, IterationState, StepUpHit))
			return false;


		bool bPerformSweepStep = false;
		if(SteppingData.bSweepStep)
		{
			bPerformSweepStep = true;
		}
		else if(StepUpHit.StepUpHeight > 3 && !GetEdgeResult(OutIterationHit).IsEdge())
		{
			// We first detected this as a low ground,
			// but where unable to actually find the edge,
			// so this must then be a tilted wall.
			// Unless the step up height is very small, because that can also make us fail the edge detection.
			// But we still keep this as a ground type, so we now redirect along the walkable slope angle
			bPerformSweepStep = true;
		}

		if(bPerformSweepStep)
		{
			FMovementHitResult GroundHit = OutIterationHit;
#if !RELEASE
			GroundHit.TraceTag = FHazeTraceTag(FName(OutIterationHit.TraceTag.ToString() + " StepUpGround"));
#endif

			if(GroundHit.Type != EMovementImpactType::Ground)
			{
				GroundHit.Type = EMovementImpactType::Ground;
				
				// If we have a grounded state at the wall impact, we use that impacts normal so we don't get weird redirects
				if(IterationState.PhysicsState.GroundContact.IsAnyGroundContact())
					GroundHit.OverrideNormals(GroundHit.Normal, IterationState.PhysicsState.GroundContact.ImpactNormal);
				// If not, we use the normal as both normals, so we don't use the 
				else 
					GroundHit.OverrideNormals(GroundHit.Normal, GroundHit.Normal);
			}

			// This is just the first redirect setup, no actual movement is performed
			// so we just leaves and let the normal redirect handle the rest
			if(!bApplyMovement)
			{
				// Temp test with not having this
				// if(GetStepUpSize() > 0)
				// {
				// 	// when we do the first redirect, we require a very small location change
				// 	// without this, for some reason, we get stuck on the edge of the physics shape
				// 	// not being able to sweep over it.
				// 	// We store this offset so that we can remove it at the end of this iteration.
				// 	StepUpSafetyOffset.Set(IterationState.WorldUp * 0.5);
				// 	IterationState.CurrentLocation += StepUpSafetyOffset.Value;
				// }

				return false;
			}

#if !RELEASE
			ResolverTemporalLog.MovementHit(GroundHit, IterationTraceSettings.TraceShape, IterationTraceSettings.CollisionShapeOffset);
#endif

			HandleIterationDeltaMovementImpact(GroundHit);
			return true;
		}

		// We need to use the old locations horizontal position, since we only want to do a step straight up
		FVector NewImpactLocation = OutIterationHit.Location.VectorPlaneProject(CurrentWorldUp) + StepUpHit.Location.ProjectOnToNormal(CurrentWorldUp);
		OutIterationHit.Type = EMovementImpactType::Ground;
		OutIterationHit.bIsStepUp = true;
		OutIterationHit.StepUpHeight = StepUpHit.StepUpHeight;
		OutIterationHit.OverrideLocation(NewImpactLocation);
		OutIterationHit.OverrideNormals(StepUpHit.Normal, StepUpHit.ImpactNormal);

#if !RELEASE
		ResolverTemporalLog.OverwriteMovementHit(OutIterationHit);
#endif

		if(bApplyMovement)
			IterationState.ApplyMovement(OutIterationHit.Time, NewImpactLocation);

		ApplyImpactOnDeltas(IterationState, OutIterationHit);
		return true;
	}

	protected bool TryAlignWorldUpWithGround(FMovementHitResult& CurrentGroundImpact)
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"TryAlignWorldUpWithGround");
#endif

		if(!ShouldAlignWorldUpWithGround())
			return false;

		if(!CurrentGroundImpact.IsWalkableGroundContact())
			return false;

		if(!CanPerformGroundTrace())
			return false;
		
		const float AlignedStepDownSize = GetStepDownSize();
		if(AlignedStepDownSize <= 0)
			return false;
		
		if(CurrentGroundImpact.EdgeType == EMovementEdgeType::Unset)
			ApplyGroundEdgeInformation(CurrentGroundImpact);

		if(CurrentGroundImpact.IsOnAnEdge() && SteppingData.EdgeHandling == EMovementEdgeHandlingType::Stop)
			return false;

		FVector PotentialNewWorldUp = CurrentGroundImpact.ImpactNormal;
		if(SteppingData.EdgeHandling == EMovementEdgeHandlingType::Follow
			&& CurrentGroundImpact.IsOnAnEdge())
		{
			PotentialNewWorldUp = CurrentGroundImpact.Normal;
		}

		if(PotentialNewWorldUp.Equals(CurrentWorldUp))
			return false;
		
		// Start by applying the new world up on the temp settings
		FMovementResolverState AlignedState = IterationState;

		// We trace perform the new grounded trace with the new ground normal.
		// But since we are turning the capsule, we start a bit up,
		// and trace a little bit extra so we don't end up inside anything
		// Its very important that we move the actor up before we change the world up.
		// By doing so, we will rotate around the radius of the trace shape
		const float BonusTrace = SteppingData.ShapeSizeForMovement * 0.1;
		AlignedState.CurrentLocation += PotentialNewWorldUp * BonusTrace;

		FHazeMovementTraceSettings AlignedTraceSettings = IterationTraceSettings;
		ChangeCurrentWorldUp(AlignedState, AlignedTraceSettings, PotentialNewWorldUp);

		FMovementResolverGroundTraceSettings GroundTraceSettings;
		GroundTraceSettings.bResolveStartPenetrating = false;
		GroundTraceSettings.CustomTraceTag = n"Validate align world up with ground";

		FMovementHitResult AlignedGround = QueryGroundShapeTrace(
			AlignedTraceSettings, 
			AlignedState.CurrentLocation, 
			-PotentialNewWorldUp * (AlignedStepDownSize + BonusTrace),
			PotentialNewWorldUp,
			GroundTraceSettings);

		if(!AlignedGround.IsAnyWalkableContact())
			return false;
		
		// Sometimes, we hit the old ground when going into concave shapes. That means that we have not walked over
		// enough and we need to keep the old ground so we don't start jitter
		// back and fourth going over to the new alignment ground
		if(!AlignedGround.ImpactNormal.Equals(CurrentGroundImpact.ImpactNormal))
			return false;

		// Finalize the new grounded location
		AlignedState.CurrentLocation = AlignedGround.Location;

		IterationState = AlignedState;
		IterationTraceSettings = AlignedTraceSettings;
		CurrentGroundImpact = AlignedGround;
		
		if(SteppingData.EdgeHandling == EMovementEdgeHandlingType::Follow
			&& CurrentGroundImpact.IsOnAnEdge())
		{
			// If we can't leave edges, we must enforce that this is just an edge type
			CurrentGroundImpact.EdgeResult.Type = EMovementEdgeType::Edge;
		}
		return true;
	}

	protected bool CanPerformGroundTrace() const
	{
		if(IsLeavingGround())
			return false;

		return true;
	}

	protected float GetStepUpSize() const
	{
		return SteppingData.StepUpSize;
	}

	protected float GetStepDownSize() const
	{
		return GetStepDownSize(IterationState.PhysicsState.GroundContact);
	}

	protected float GetStepDownSize(FMovementHitResult CurrentGround) const
	{
		if(!CurrentGround.IsWalkableGroundContact())
			return SteppingData.StepDownInAirSize;

		return SteppingData.StepDownOnGroundSize + (SteppingData.SafetyDistance.Y + 0.01);
	}

	protected float GetFallOfEdgeDistance() const
	{
		return GetStepDownSize(IterationState.PhysicsState.GroundContact);
	}

	protected float GetFallOfEdgeDistance(FMovementHitResult CurrentGround) const
	{
		return GetStepDownSize(CurrentGround);
	}

	protected bool IsLeavingGround() const
	{
		if(ShouldValidateRemoteSideGroundPosition())
			return false;

		FMovementDelta Impulse = IterationState.GetDelta(EMovementIterationDeltaStateType::Impulse);
		if(Impulse.Delta.DotProduct(CurrentWorldUp) > KINDA_SMALL_NUMBER)
			return true;

		if(VerticalDirection <= 0)
			return false;

		return true;
	}

	bool ShouldAlignWorldUpWithGround() const override
	{
		return SteppingData.AlignWithImpactSettings.bAlignWithGround;
	}

	bool ShouldAlignWorldUpWithWall() const override
	{
		return SteppingData.AlignWithImpactSettings.bAlignWithWall;
	}

	bool ShouldAlignWorldUpWithCeiling() const override
	{
		return SteppingData.AlignWithImpactSettings.bAlignWithCeiling;
	}

	const FVector& GetCurrentWorldUp() const property override
	{
		return IterationState.WorldUp;
	}

	protected void ChangeCurrentWorldUp(FMovementResolverState& State, FHazeMovementTraceSettings& TraceSettings, FVector NewWorldUp) const
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"ChangeCurrentWorldUp");
#endif

		if(!ensure(NewWorldUp.IsUnit()))
			return;

		if(!ensure(!NewWorldUp.Equals(State.WorldUp)))
			return;

#if !RELEASE
		ResolverTemporalLog.DirectionalArrow("New WorldUp", IterationState.CurrentLocation, NewWorldUp, 2, 200, FLinearColor::Green);
		ResolverTemporalLog.DirectionalArrow("Previous WorldUp", IterationState.CurrentLocation, State.WorldUp, 2, 200, FLinearColor::Red);
#endif

		State.WorldUp = NewWorldUp;

#if !RELEASE
		FMovementDelta PreviousMovementDelta = State.GetDelta(EMovementIterationDeltaStateType::Movement);
		FMovementDelta PreviousHorizontalDelta = State.GetDelta(EMovementIterationDeltaStateType::Horizontal);
#endif

		State.ChangeDeltaWorldUp(EMovementIterationDeltaStateType::Movement, NewWorldUp);
		State.ChangeDeltaWorldUp(EMovementIterationDeltaStateType::Horizontal, NewWorldUp);

#if !RELEASE
		ResolverTemporalLog.MovementDelta("New Movement", IterationState.CurrentLocation, State.GetDelta(EMovementIterationDeltaStateType::Movement), InColor = FLinearColor::Green);
		ResolverTemporalLog.MovementDelta("Previous Movement", IterationState.CurrentLocation, PreviousMovementDelta);

		ResolverTemporalLog.MovementDelta("New Horizontal", IterationState.CurrentLocation, State.GetDelta(EMovementIterationDeltaStateType::Horizontal), InColor = FLinearColor::Green);
		ResolverTemporalLog.MovementDelta("Previous Horizontal", IterationState.CurrentLocation, PreviousHorizontalDelta);
#endif

		State.CurrentRotation = FinalizeRotation(State.CurrentRotation, NewWorldUp);
		TraceSettings.UpdateRotation(State.CurrentRotation);
	}

	/**
	 * Change our current ground contact.
	 * @param bApplyGroundEdgeInformation Should ApplyGroundEdgeInformation() be called on NewGroundHit?
	 */
	void ChangeGroundedState(FMovementResolverState& State, FMovementHitResult& NewGroundHit, bool bApplyGroundEdgeInformation = true)
	{
		MovementSinceGroundedValidation = 0;
		if(bApplyGroundEdgeInformation)
			ApplyGroundEdgeInformation(NewGroundHit);

		if(NewGroundHit.IsWalkableGroundContact() && NewGroundHit.IsOnUnstableEdge())
		{
			switch(SteppingData.WalkOnUnstableEdgeHandling)
			{
				case ESteppingWalkOnUnstableEdgeHandling::Ignored:
					break;

				case ESteppingWalkOnUnstableEdgeHandling::Invalid:
					NewGroundHit.OverrideNoImpact();
					break;

				case ESteppingWalkOnUnstableEdgeHandling::Unwalkable:
					NewGroundHit.bIsWalkable = false;
					break;
			}
		}

		State.PhysicsState.GroundContact = NewGroundHit;
	}

	FMovementEdge GetEdgeResult(FMovementHitResult HitResult) const
	{
		// Already applied
		if(HitResult.EdgeType != EMovementEdgeType::Unset)
			return HitResult.EdgeResult;

		FVector MovementDirection = IterationState.GetHorizontalMovementDirection(CurrentWorldUp);
		if(MovementDirection.IsNearlyZero())
			 MovementDirection = IterationState.CurrentRotation.ForwardVector;

		return GetEdgeInformation(HitResult, MovementDirection, SteppingData.EdgeRedirectType);	
	}

	/** Applies the edge information to the movement hit result */
	protected void ApplyGroundEdgeInformation(FMovementHitResult& HitResult, bool bForceEvenIfSet = false, bool bApplyFallOfEdgeDistance = true) const
	{	
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"ApplyGroundEdgeInformation");
#endif

		if(SteppingData.EdgeHandling == EMovementEdgeHandlingType::None)
			return;

		if(HitResult.EdgeResult.Type != EMovementEdgeType::Unset && !bForceEvenIfSet)
			return;

		if(!HitResult.IsAnyGroundContact())
			return;

		const bool bFollowEdges = SteppingData.EdgeHandling == EMovementEdgeHandlingType::Follow;
		FVector MovementDirection = IterationState.GetHorizontalMovementDirection(CurrentWorldUp);
		if(MovementDirection.IsNearlyZero())
			 MovementDirection = IterationState.CurrentRotation.ForwardVector;

		// If we are set to follow edges, and the angle between the impact normal and the normal is bigger than the walkable distance,
		// we call this and edge directly
		float AngleBetweenNormals = HitResult.Normal.GetAngleDegreesTo(HitResult.ImpactNormal);
		if(bFollowEdges && AngleBetweenNormals > SteppingData.WalkableSlopeAngle)
		{
			FMovementEdge& EdgeInfo = HitResult.EdgeResult;
			EdgeInfo.Type = EMovementEdgeType::Edge;
			EdgeInfo.Distance = 0;
			EdgeInfo.EdgeNormal = HitResult.Normal;
			EdgeInfo.GroundNormal = EdgeInfo.EdgeNormal;
			EdgeInfo.bIsOnEmptySideOfLedge = false;
		}
		// Else we trace for an edge the normal way
		else
		{
			HitResult.EdgeResult = GetEdgeInformation(HitResult, MovementDirection, SteppingData.EdgeRedirectType);	
			
			FMovementEdge& EdgeInfo = HitResult.EdgeResult;
			if(EdgeInfo.IsEdge())
			{
				if(bFollowEdges)
				{
					EdgeInfo.bMovingPastEdge = false;
					EdgeInfo.bIsOnEmptySideOfLedge = false;
					EdgeInfo.EdgeNormal = HitResult.Normal;
					EdgeInfo.GroundNormal = EdgeInfo.EdgeNormal;

					if(EdgeInfo.EdgeNormal.Parallel(EdgeInfo.GroundNormal, KINDA_SMALL_NUMBER))
					{
						// Same normals can not be an edge!
						EdgeInfo.Type = EMovementEdgeType::NoEdge;
					}
				}
				else
				{
					EdgeInfo.UnstableDistance = SteppingData.MaxEdgeDistanceUntilUnstable;

					// If we are leaving the edge, we ignore the low ground information
					if(!IsLeavingEdge(HitResult))
					{
						FMovementHitResult StepUp;
						if(!HitResult.IsStepupGroundContact())
							GetLowGroundStepUpImpact(HitResult, IterationState, StepUp);
		
						// This is just an edge on a low wall, so no need to validate the falloff distance at this point
						if(StepUp.IsStepupGroundContact())
						{
							EdgeInfo.bMovingPastEdge = false;
							EdgeInfo.bIsOnEmptySideOfLedge = false;
							EdgeInfo.UnstableDistance = -1;
						}
					}
					else
					{
						const float FallOfEdgeDistanceToUse = GetFallOfEdgeDistance(HitResult);
						if(bApplyFallOfEdgeDistance && FallOfEdgeDistanceToUse > 0)
						{
							FVector EdgeLocation = HitResult.ImpactPoint;
							EdgeLocation += CurrentWorldUp * ((SteppingData.ShapeSizeForMovement * 0.5) + SteppingData.SafetyDistance.Y);

							const FVector HorizontalEdgeCliffDirection = EdgeInfo.EdgeNormal.VectorPlaneProject(CurrentWorldUp).GetSafeNormal();
							EdgeLocation += HorizontalEdgeCliffDirection * (SteppingData.ShapeSizeForMovement + 1);

							FVector EdgeNormal = EdgeInfo.EdgeNormal;
							bool bIsMovingTowardsEdge = EdgeInfo.bMovingPastEdge;	

							// This is an edge with ground on both sides.
							// So if we want to check edges further out, we need to make a edge normal
							if(EdgeNormal.IsNearlyZero() && SteppingData.MaxEdgeDistanceUntilUnstable > 0)
							{
								EdgeNormal = MovementDirection;
								bIsMovingTowardsEdge = true;
							}

							if(!EdgeNormal.IsNearlyZero())
							{
								if(SteppingData.MaxEdgeDistanceUntilUnstable > 0 && bIsMovingTowardsEdge)
								{
									EdgeLocation += HorizontalEdgeCliffDirection * (EdgeInfo.Distance);

									FVector TraceDir = -CurrentWorldUp.VectorPlaneProject(EdgeNormal).GetSafeNormal();
									EdgeLocation += TraceDir * SteppingData.MaxEdgeDistanceUntilUnstable;
								}
									
								FMovementResolverGroundTraceSettings GroundTraceSettings;
								GroundTraceSettings.CustomTraceTag = n"EdgeCliffSideGroundTrace";
								GroundTraceSettings.bResolveStartPenetrating = false;

								const float TraceLength = FallOfEdgeDistanceToUse + SteppingData.SafetyDistance.Y;
								auto ValidateGround = QueryGroundShapeTrace(EdgeLocation, -CurrentWorldUp * TraceLength, GroundTraceSettings);
								if(ValidateGround.bStartPenetrating || ValidateGround.IsAnyGroundContact())
								{
									EdgeInfo.bMovingPastEdge = false;
									EdgeInfo.bIsOnEmptySideOfLedge = false;
								}
								else
								{
									EdgeInfo.bIsOnEmptySideOfLedge = true;
								}
							}
						}
					}
				}
			}
		}

#if !RELEASE
		ResolverTemporalLog.OverwriteMovementHit(HitResult);
#endif

#if EDITOR
		// If we are on an edge, it must also be a valid edge!
		MovementCheck(!HitResult.EdgeResult.IsEdge() || HitResult.EdgeResult.IsValidEdge());
#endif
	}

	void TryHandleLandOnUnstableEdge(FMovementHitResult& PendingGround, FMovementResolverState& State) const
	{
		if(SteppingData.LandOnUnstableEdgeHandling == ESteppingLandOnUnstableEdgeHandling::None)
			return;

		// If the pending ground is not actually ground, it can't be a landing
		if(!PendingGround.IsAnyGroundContact())
			return;

		// If we are already on the ground, this can't be a landing
		if(IterationState.PhysicsState.GroundContact.IsWalkableGroundContact())
			return;

		ApplyGroundEdgeInformation(PendingGround);

		if(!PendingGround.IsOnUnstableEdge())
			return;

		switch(SteppingData.LandOnUnstableEdgeHandling)
		{
			case ESteppingLandOnUnstableEdgeHandling::None:
				break;

			case ESteppingLandOnUnstableEdgeHandling::Slide:
			{
				// Making the hit unwalkable will cause us to slide along it
				PendingGround.bIsWalkable = false;
				break;
			}

			case ESteppingLandOnUnstableEdgeHandling::Adjust:
			{
				// Move us out to outside the edge
				// FB TODO: There is a slight risk here of our shape ending up inside of collision, is that a problem? Would be nice to not need a trace here... Should be kind of safe since the edge detection traces this side.
				State.CurrentLocation = State.CurrentLocation.PointPlaneProject(PendingGround.ImpactPoint, PendingGround.EdgeResult.EdgeNormal);
				State.CurrentLocation += PendingGround.EdgeResult.EdgeNormal * (SteppingData.ShapeSizeForMovement + SteppingData.SafetyDistance.X);

				// Make sure that we have no delta into the edge

				if(State.DeltaToTrace.DotProduct(PendingGround.EdgeResult.EdgeNormal) < 0)
					State.DeltaToTrace = State.DeltaToTrace.VectorPlaneProject(PendingGround.EdgeResult.EdgeNormal);

				for(auto It : State.DeltaStates)
				{
					const EMovementIterationDeltaStateType DeltaType = It.Key;
					FMovementDelta MovementDelta = It.Value.ConvertToDelta();

					if(MovementDelta.IsNearlyZero())
						continue;

					MovementDelta = MovementDelta.LimitToNormal(PendingGround.EdgeResult.EdgeNormal);

		#if !RELEASE
					ResolverTemporalLog.MovementDelta(f"New {It.Key:n}", State.CurrentLocation, MovementDelta, InColor = FLinearColor::Green);
					ResolverTemporalLog.MovementDelta(f"Previous {It.Key:n}", State.CurrentLocation, It.Value.ConvertToDelta());
		#endif

					State.OverrideDelta(DeltaType, MovementDelta);
				}

				// If we adjust, we don't actually want to hit the edge
				PendingGround = FMovementHitResult();
				break;
			}
		}
	}

	protected bool GetLowGroundStepUpImpact(FMovementHitResult WallImpact, FMovementResolverState State, FMovementHitResult& OutStepUpHit) const
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"GetLowGroundStepUpImpact");
#endif

		const float StepUpSize = GetStepUpSize();

#if !RELEASE
		ResolverTemporalLog.Value("StepUpSize", StepUpSize);
#endif
		if(StepUpSize < KINDA_SMALL_NUMBER)
			return false;

		const FMovementHitResult& GroundContact = State.PhysicsState.GroundContact;
		FVector GroundLocation = WallImpact.Location;
		if(GroundContact.IsAnyGroundContact())
			GroundLocation = GroundContact.Location;

		// Use bottom of shape
		GroundLocation = State.ConvertLocationToShapeBottomLocation(GroundLocation, IterationTraceSettings);

		const FVector TraceDirection = WallImpact.TraceDirection;
		const FVector ImpactNormal = WallImpact.ImpactNormal;

		// We should only trigger a step up if we are moving towards the surface horizontally.
		if (ImpactNormal.DotProduct(TraceDirection) > 0.0)
			return false;

		const FVector ImpactPoint = WallImpact.ImpactPoint;
		const FVector ImpactPointDelta = ImpactPoint - GroundLocation;
		float StepHeight = ImpactPointDelta.DotProduct(State.WorldUp);

#if !RELEASE
		ResolverTemporalLog.Value("StepHeight", StepHeight);
#endif

		if(StepHeight >= StepUpSize - KINDA_SMALL_NUMBER)
			return false;
		
		// If the normals align with the world up, this can't be a low ground.
		const bool bNormalIsAlignedWithWorldUp = WallImpact.Normal.DotProduct(State.WorldUp) > 1.0 - KINDA_SMALL_NUMBER;

		if (bNormalIsAlignedWithWorldUp)
		{
			// This used to only check the normal, not impact normal, but that could fail when the impact normal was a wall but the normal was ground.
			const bool bImpactNormalIsAlignedWithWorldUp = WallImpact.ImpactNormal.DotProduct(State.WorldUp) > 1.0 - KINDA_SMALL_NUMBER;
			if(bImpactNormalIsAlignedWithWorldUp)
				return false;
		}

		FVector InwardsDirection = -WallImpact.Normal.VectorPlaneProject(State.WorldUp).GetSafeNormal();
		if(InwardsDirection.IsNearlyZero())
			return false;
		
		// Validate the ground where we want to stepup so we can actually step up here
		{
			FVector TraceFrom = ImpactPoint;
			TraceFrom += InwardsDirection * SteppingData.SafetyDistance.X;
			TraceFrom += State.WorldUp * (SteppingData.ShapeSizeForMovement + SteppingData.SafetyDistance.Y);

			FVector TraceDownDelta = -State.WorldUp * (SteppingData.ShapeSizeForMovement * 2);

			OutStepUpHit = QueryShapeTrace(TraceFrom, TraceDownDelta, FHazeTraceTag(n"StepUpHit"));

			if(HandleStepUpHitDelegate.IsBound())
			{
				bool bModifiedStepUpHit = false;
				bool bRetryStepUpTrace = false;
				HandleStepUpHitDelegate.ExecuteIfBound(OutStepUpHit, bModifiedStepUpHit, bRetryStepUpTrace);
#if !RELEASE
				if(bModifiedStepUpHit)
					ResolverTemporalLog.OverwriteMovementHit(OutStepUpHit);
#endif
				if(bRetryStepUpTrace)
					OutStepUpHit = QueryShapeTrace(TraceFrom, TraceDownDelta, FHazeTraceTag(n"StepUpHit_Retry"));
			}

			if(!OutStepUpHit.IsAnyGroundContact())
				return false;
		}

		// You can land on an edge, with no ground underneath. The stepup height will still be valid
		// so we also need to validate the distance to the ground underneath the impact
		bool bRequireGroundBeneathEdge = true;
		if(GroundContact.IsWalkableGroundContact() || (GroundContact.IsOnAnEdge() && !GroundContact.IsOnUnstableEdge()))
		{
			// We are standing on valid ground, or on a stable edge. No need to check for ground under the step up hit
			bRequireGroundBeneathEdge = false;
		}

		if(bRequireGroundBeneathEdge)
		{
			const FHazeTraceTag TraceTag = FHazeTraceTag(n"StepUpGroundHit");
			FVector TraceFrom = ImpactPoint;
			TraceFrom += -InwardsDirection * (SteppingData.ShapeSizeForMovement + SteppingData.SafetyDistance.X + 1);
			FVector TraceDownDelta = -State.WorldUp * GetStepUpSize();
			FHitResult GroundHit = IterationTraceSettings.QueryShapeTrace(TraceFrom, TraceDownDelta, TraceTag);

#if !RELEASE
			ResolverTemporalLog.HitResult(TraceTag.ToString(), GroundHit, IterationTraceSettings.TraceShape, IterationTraceSettings.CollisionShapeOffset);
#endif

			if(!GroundHit.IsValidBlockingHit()
			&& !GroundHit.bStartPenetrating) // If it is start penetrating, we are in a slope and it is already valid ground
				return false;
		}

		const FVector StepUpDelta = State.ConvertLocationToShapeBottomLocation(WallImpact.Location, IterationTraceSettings) - State.ConvertLocationToShapeBottomLocation(OutStepUpHit.Location, IterationTraceSettings);
		StepHeight = Math::Abs(StepUpDelta.DotProduct(State.WorldUp));

#if !RELEASE
		ResolverTemporalLog.Value("Validation StepHeight", StepHeight);
#endif

		if(StepHeight >= StepUpSize - KINDA_SMALL_NUMBER)
		{
			// The final step up height we found was simply too high to step up on
			return false;
		}
		
		OutStepUpHit.bIsStepUp = true;
		OutStepUpHit.StepUpHeight = StepHeight;

#if !RELEASE
		ResolverTemporalLog.OverwriteMovementHit(OutStepUpHit);
#endif

		return true;
	}

	protected void ApplyGroundOverride()
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"ApplyGroundOverride");
#endif

		switch(SteppingData.OverrideFinalGroundContactType)
		{
			case EMovementOverrideFinalGroundType::None:
				break;

			// Simple just override the final ground as requested
			case EMovementOverrideFinalGroundType::Active:
			{
				auto GroundImpact = GenerateDefaultGroundedState(SteppingData.OverrideFinalGroundContact, CurrentWorldUp, FHazeTraceTag(n"GroundOverride"));
				ChangeGroundedState(IterationState, GroundImpact);
				break;
			}

			// The override wants to find an actual valid grounded location
			case EMovementOverrideFinalGroundType::ActiveWithValidation:
			{
				if(!SteppingData.OverrideFinalGroundContact.IsValidBlockingHit())
					break;

				FMovementResolverGroundTraceSettings GroundTraceSettings;
				GroundTraceSettings.bRedirectTraceIfInvalidGround = false;
				GroundTraceSettings.CustomTraceTag = n"ValidateOverrideGround";
				
				auto GroundImpact = QueryGroundShapeTrace(
					SteppingData.OverrideFinalGroundContact.Location + (CurrentWorldUp * SteppingData.SafetyDistance.Y), 
					-CurrentWorldUp * SteppingData.ShapeSizeForMovement * 2,
					GroundTraceSettings,
				);

				ChangeGroundedState(IterationState, GroundImpact);
				break;
			}
		}
	}
}
