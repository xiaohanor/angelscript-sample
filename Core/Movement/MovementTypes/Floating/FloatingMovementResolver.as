/**
 * EXPERIMENTAL: Might be merged into SweepingMovement in the future.
 * Floating Movement is very similar to Sweeping Movement, but has the added feature that the collider will sweep slightly above the ground, instead of along it.
 * This helps prevent colliding with small edges on the ground, while not forcing you to use the full SteppingMovement.
 */
class UFloatingMovementResolver : UBaseMovementResolver
{
	default RequiredDataType = UFloatingMovementData;
	private const UFloatingMovementData FloatingData;

	FVector FloatingDirection;
	TOptional<float> PerformedFloatingHeight;

	bool bIterationIsSquished = false;
	float VerticalDeltaGroundTraceDistance = 0;
	bool bPerformSubStep = false;
	FString PerformSubStepReason = "";
	float MaxSubStepTraceLength = 0;
	int BonusSubStepIterations = 0;
	bool bScopedKeepVelocityInRedirections = false;
	bool bStickToGround = false;

	void PrepareResolver(const UBaseMovementData Movement) override
	{
		FloatingData = Cast<UFloatingMovementData>(Movement);

		Super::PrepareResolver(Movement);

#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"PrepareResolver");
#endif

		IterationState.InitFromMovementData(FloatingData);
		IterationState.CurrentRotation = FinalizeRotation(IterationState.CurrentRotation, CurrentWorldUp);
		IterationTraceSettings.UpdateRotation(IterationState.CurrentRotation);

		FloatingDirection = FVector::ZeroVector;
		PerformedFloatingHeight.Reset();

		bIterationIsSquished = false;
		bPerformSubStep = false;
		MaxSubStepTraceLength = 0;
		VerticalDeltaGroundTraceDistance = 0;
		bStickToGround = false;

		check(FloatingData.EdgeHandling != EMovementEdgeHandlingType::Stop, "The Floating Movement Resolver does not support edge stopping at the moment.");

		// This requires us to sub step the movement so we detect an edge when it actually happens
		if(FloatingData.bAllowSubStep && CanPerformGroundTrace() 
			&& FloatingData.OriginalContacts.GroundContact.IsAnyGroundContact()
			&& (FloatingData.AlignWithImpactSettings.IsActive()))
		{
			bPerformSubStep = true;
			MaxSubStepTraceLength = Math::Max(FloatingData.ShapeSizeForMovement - FloatingData.SafetyDistance.X, 1);
			BonusSubStepIterations = FloatingData.MaxRedirectIterations;

#if !RELEASE	
			if(FloatingData.AlignWithImpactSettings.IsActive())
				PerformSubStepReason = "Align With Impact";
			DebugValidateMoveAmount(GenerateIterationDelta().Delta, MaxSubStepTraceLength, BonusSubStepIterations, PerformSubStepReason);
#endif
		}
	}

#if EDITOR
	void ResolveRerun() override
	{
		check(FloatingData != nullptr);

		Resolve();
		PostResolve();

		// Did the rerun succeed
		check(FloatingData.DebugFinalTransform.Equals(FTransform(IterationState.CurrentRotation, IterationState.CurrentLocation)));
	}
#endif

	void ResolveAndApplyMovementRequest(UHazeMovementComponent MovementComponent) override
	{
#if !RELEASE
	 	check(FloatingData != nullptr);
		check(!MovementComponent.IsApplyingInParallel());
#endif

#if EDITOR
		// In the editor, we add the rerun each movement frame
		UFloatingMovementData RerunData = Cast<UFloatingMovementData>(MovementComponent.AddRerunData(FloatingData, this));
#endif

#if !RELEASE
		// Temporal log the first iteration state
		MovementDebug::AddInitialDebugInfo(MovementComponent, FloatingData, this);
#endif

		// This will resolve the transient state
		// and save the result in the "FinalResult" param
		Resolve();
		PostResolve();

		ApplyResolve(MovementComponent);

#if EDITOR
		// Update the final transform for rerun data so we can validate that
		if(RerunData != nullptr)
			RerunData.DebugFinalTransform = FTransform(IterationState.CurrentRotation, IterationState.CurrentLocation);
#endif

#if !RELEASE
		// Temporal log the final state
		MovementDebug::AddMovementResolvedState(
			MovementComponent,
			FloatingData,
			this,
			IterationState,
			FloatingData.IterationTime
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
		MovementComponent.SetMovingStatus(true, FloatingData.StatusInstigator);
		auto MoveComp = Cast<UHazeMovementComponent>(MovementComponent);
		ApplyResolvedData(MoveComp);
		PostApplyResolvedData(MoveComp);
		MovementComponent.SetMovingStatus(false, FloatingData.StatusInstigator);
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
			if (IterationState.PhysicsState.GroundContact.IsAnyGroundContact())
			{
				MovementComponent.StopFalling(IterationState.CurrentLocation, MovementComponent.PreviousVelocity);
			}
		}
		// Start falling
		else
		{
			if (!IterationState.PhysicsState.GroundContact.IsAnyGroundContact() && CurrentWorldUp.DotProduct(FinalVerticalVelocity) < SMALL_NUMBER)
			{
				MovementComponent.StartFalling(IterationState.CurrentLocation);
			}
		}

		// Finally, apply the actor location and rotation
		MovementComponent.HazeOwner.SetActorLocationAndRotation(IterationState.CurrentLocation, IterationState.CurrentRotation);
	}

	protected void GetResolvedVelocityToApply(FVector& OutHorizontal, FVector& OutVertical) const
	{
		if(bIterationIsSquished)
			return;
		
		const FVector FinalVelocity = IterationState.GetDelta().Velocity;
		OutHorizontal = FinalVelocity.VectorPlaneProject(CurrentWorldUp);
		OutVertical = FinalVelocity - OutHorizontal;

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

		// First iteration
		// We start with fixing the current ground
		// and applying the deltas upon that
		if (IterationCount == 1)
		{
			PrepareFirstIteration();
		}

		FloatingDirection = GetFloatingDirection();
		check(FloatingDirection.IsNormalized());

		// Trace the delta and handle potential overlap
		IterationState.DeltaToTrace = GenerateIterationDelta().Delta;
		const float DeltaSizeSq = IterationState.DeltaToTrace.SizeSquared();

		// This requires us to sub step the movement so we detect an edge when it actually happens
		if(bPerformSubStep && DeltaSizeSq > Math::Square(IterationTraceSettings.TraceLengthClamps.Min))
		{
			const FVector MaxDelta = IterationState.DeltaToTrace.GetClampedToMaxSize(MaxSubStepTraceLength);
			IterationState.AlphaModifier = MaxDelta.Size() / IterationState.DeltaToTrace.Size();
			IterationState.DeltaToTrace = MaxDelta;
		}
		
		// we have ended upp inside something and can't move anymore
		if(bIterationIsSquished)
			return false;

		if(IterationCount > FloatingData.MaxRedirectIterations)
			return false;

		if(IterationState.RemainingMovementAlpha < SMALL_NUMBER)
			return false;

		if(DeltaSizeSq <= Math::Square(IterationTraceSettings.TraceLengthClamps.Min))
		{
			IterationState.DeltaToTrace = FVector::ZeroVector;
			return false;
		}

		// FLOATING: We move up as if we did a step up before the iteration sweep
		switch(FloatingData.ValidationMethod)
		{
			case EFloatingMovementValidateMethod::NoValidation:
				break;

			case EFloatingMovementValidateMethod::ValidateSweep:
				PerformedFloatingHeight = ValidateFloating_SweepUp(IterationState.CurrentLocation);
				break;

			case EFloatingMovementValidateMethod::ValidateOverlap:
				PerformedFloatingHeight = ValidateFloating_Overlap(IterationState.CurrentLocation);
				break;
		}

		return true;
	}

	protected void PrepareFirstIteration()
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"PrepareFirstIteration");
#endif
		check(IterationCount == 1);

		// We start with fixing the current ground
		if(CanPerformGroundTrace())
		{
			const FVector PendingDelta = GenerateIterationDelta().Delta;
			FMovementHitResult InitialGround = FloatingData.OriginalContacts.GroundContact;

			if(InitialGround.IsAnyGroundContact())
			{
				// If we are grounded,
				// we need to extract the delta on the grounded planes normal
				FVector VerticalPlane = InitialGround.ImpactNormal;
	
				// We transfer the gravity amount into a ground trace if we are grounded from start, so we don't lose that
				// down trace in the end. This is because the redirects remove any vertical delta point into the ground
				// when applying the first ground redirect
				VerticalDeltaGroundTraceDistance = Math::Abs(Math::Min(PendingDelta.DotProduct(VerticalPlane), 0));

				// Make sure we have the correct ground impact when we redirect
				ChangeGroundedState(InitialGround);

				// if our velocity is pointing down into the ground
				// we start with redirecting against the ground
				if(VerticalDeltaGroundTraceDistance > 0 || FloatingData.EdgeHandling == EMovementEdgeHandlingType::Follow)
					ApplyImpactOnDeltas(InitialGround);

				// If we are actually trying to leave an edge,
				// we don't apply the ground stickyness.
				// This might be added as a separate setting but the wanted behavior
				// is that you always "fly" out over edges  
				if(!IsLeavingEdge(InitialGround))
				{
					VerticalDeltaGroundTraceDistance += FloatingData.BonusGroundedTraceDistanceWhileGrounded;
					bStickToGround = FloatingData.BonusGroundedTraceDistanceWhileGrounded > 0;
				}	
			}
		}
	}

	protected void ChangeGroundedState(FMovementHitResult NewGroundHit)
	{
		IterationState.PhysicsState.GroundContact = NewGroundHit;
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

	protected void HandleIterationDeltaMovementGroundImpact(FMovementHitResult& MovementHit)
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"HandleIterationDeltaMovementGroundImpact");
#endif

		check(MovementHit.Type == EMovementImpactType::Ground);

		if(HandleMovementImpactInternal(MovementHit, EMovementResolverAnyShapeTraceImpactType::Iteration))
		{
			// FLOATING: Always consume if something handled the impact
			// FB TODO: Validation?
			ConsumeFloatingHeight(true);
			return;
		}

		TryAlignWorldUpWithImpact(MovementHit);
		ApplyGroundEdgeInformation(MovementHit);
		ApplyImpactOnDeltas(MovementHit);
		ChangeGroundedState(MovementHit);
		ConsumeFloatingHeight(false);
		IterationState.ApplyMovement(MovementHit.Time, MovementHit.Location);
	}

	protected void HandleIterationDeltaMovementWallImpact(FMovementHitResult& MovementHit)
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"HandleIterationDeltaMovementWallImpact");
#endif

		check(MovementHit.Type == EMovementImpactType::Wall);

		if(HandleMovementImpactInternal(MovementHit, EMovementResolverAnyShapeTraceImpactType::Iteration))
		{
			// FLOATING: Always consume if something handled the impact
			// FB TODO: Validation?
			ConsumeFloatingHeight(true);
			return;
		}

		// We always need to update the ground where we hit the wall first
		// so we align correctly with the wall impact
		const float GroundTraceAtWallDistance = GetGroundTraceDistance();
		FMovementHitResult GroundAtWallImpact;
		if(GroundTraceAtWallDistance > 0
			&& CanPerformGroundTrace()
			&& IterationState.PhysicsState.GroundContact.IsAnyGroundContact())
		{
			// When we hit a wall, we usually need to validate
			// the ground at the wall.
			// But the wall might be a very small wall under the shape size
			// so we then need to use the normal instead to validate the impact
			FMovementResolverGroundTraceSettings GroundTraceSettings;
			GroundTraceSettings.NormalForImpactTypeGenerationType = EMovementResolverNormalForImpactTypeGenerationType::ImpactNormal;
			GroundTraceSettings.bRedirectTraceIfInvalidGround = true;
			GroundTraceSettings.CustomTraceTag = n"GroundTraceAtWall";
			GroundAtWallImpact = QueryGroundShapeTrace(MovementHit.Location,
				-FloatingDirection * GroundTraceAtWallDistance,
				GroundTraceSettings);

			if(GroundAtWallImpact.IsValidBlockingHit() && HandleMovementImpactInternal(GroundAtWallImpact, EMovementResolverAnyShapeTraceImpactType::GroundAtWall))
			{
				// FLOATING: Always consume if something handled the impact
				// FB TODO: Validation?
				ConsumeFloatingHeight(true);
				return;
			}

			ApplyGroundEdgeInformation(GroundAtWallImpact);

			// Update the grounded state before we perform the wall impact
			ChangeGroundedState(GroundAtWallImpact);
		}

		const bool bPerformedAlignment = TryAlignWorldUpWithImpact(MovementHit);

		// Normal movement
		if(!FloatingData.bHasSyncedLocationInfo || bPerformedAlignment)
		{
			// Always apply the wall impact on the deltas
			ApplyImpactOnDeltas(MovementHit);
			IterationState.PhysicsState.WallContact = MovementHit;

			if(GroundAtWallImpact.IsAnyGroundContact())
			{
				// Put us on the ground impact
				IterationState.ApplyMovement(MovementHit.Time, GroundAtWallImpact.Location);
				ConsumeFloatingHeight(false);
			}
			else
			{
				// Put us on the movement hit, then consume floating height to move us down again
				IterationState.ApplyMovement(MovementHit.Time, MovementHit.Location);
				ConsumeFloatingHeight(true);
			}
		}
		// Remote side movement without any alignment
		// need to be able to go through walls so we don't get stuck on edges
		else
		{
			IterationState.PhysicsState.WallContact = MovementHit;
			HandleIterationDeltaMovementWithoutImpact();
		}
	}

	protected void HandleIterationDeltaMovementCeilingImpact(FMovementHitResult& MovementHit)
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"HandleIterationDeltaMovementCeilingImpact");
#endif

		check(MovementHit.Type == EMovementImpactType::Ceiling);

		if(HandleMovementImpactInternal(MovementHit, EMovementResolverAnyShapeTraceImpactType::Iteration))
		{
			// FLOATING: Always consume if something handled the impact
			// FB TODO: Validation?
			ConsumeFloatingHeight(true);
			return;
		}

		const bool bPerformedAlignment = TryAlignWorldUpWithImpact(MovementHit);

		if(!bPerformedAlignment)
		{
			ConsumeFloatingHeight(true);
		}
		
		// Normal movement
		if(!FloatingData.bHasSyncedLocationInfo || bPerformedAlignment)
		{
			ApplyImpactOnDeltas(MovementHit);
			IterationState.PhysicsState.CeilingContact = MovementHit;
			IterationState.ApplyMovement(MovementHit.Time, MovementHit.Location);
		}

		// Remote side movement without any alignment
		// need to be able to go through ceilings so we don't get stuck following the control side
		else
		{
			IterationState.PhysicsState.CeilingContact = MovementHit;
			HandleIterationDeltaMovementWithoutImpact();
		}
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

		FVector PendingLocation = GetUnhinderedPendingLocation();
		IterationState.ApplyMovement(1, PendingLocation);

		// Clear the current ground so we can find a new ground
		IterationState.PhysicsState.GroundContact = FMovementHitResult();	
		
		const float CurrentGroundTraceDistance = GetGroundTraceDistance();
		if(CurrentGroundTraceDistance > 0 && CanPerformGroundTrace())
		{
			FMovementResolverGroundTraceSettings GroundTraceSettings;
			GroundTraceSettings.NormalForImpactTypeGenerationType = EMovementResolverNormalForImpactTypeGenerationType::ImpactNormal;
			GroundTraceSettings.bRedirectTraceIfInvalidGround = true;
			GroundTraceSettings.bFlatCapsuleBottom = FloatingData.bFlatCapsuleBottom;

			FMovementHitResult PendingGround = QueryGroundShapeTrace(IterationState.CurrentLocation,
				-FloatingDirection * CurrentGroundTraceDistance,
				GroundTraceSettings);

			if(PendingGround.IsValidBlockingHit() && HandleMovementImpactInternal(PendingGround, EMovementResolverAnyShapeTraceImpactType::Ground))
			{
				// FLOATING: Always consume if something handled the impact
				// FB TODO: Validation?
				ConsumeFloatingHeight(true);
				return;
			}

			// If we can't align with impact
			// we need to handle the new grounded state
			if(!TryAlignWorldUpWithImpact(PendingGround))
			{
				if(PendingGround.IsAnyGroundContact())
				{
					ApplyGroundEdgeInformation(PendingGround);
					ChangeGroundedState(PendingGround);
					ApplyImpactOnDeltas(PendingGround);

					// Don't suck down the actor over edges
					if(!IsLeavingEdge(PendingGround))
					{					
						IterationState.CurrentLocation = PendingGround.Location;			
						ConsumeFloatingHeight(false);
					}
					else
					{
						ConsumeFloatingHeight(true);
					}
				}
				else if(PendingGround.IsValidBlockingHit())
				{
					// FLOATING: We did not find ground, but we hit something, so we must place ourselves on that
					IterationState.CurrentLocation = PendingGround.Location;
					ApplyImpactOnDeltas(PendingGround);
					ConsumeFloatingHeight(false);
				}
				else
				{
					// FLOATING: We did not find ground, which means that there is nothing beneath us. Move us down
					ConsumeFloatingHeight(true);
				}
			}
			else
			{
				// FLOATING: We aligned with the ground impact. This means that we have changed to being grounded, we need to move to be where the ground is
				IterationState.CurrentLocation = PendingGround.Location;
			}
		}
		else
		{
			// FLOATING: We could not ground trace, just move us down and hope it's fine...
			// FB TODO: Validation sweep here?
			ConsumeFloatingHeight(true);
		}
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

				// FLOATING: If we are not validating the floating sweep, run a special iteration sweep here
				// FB TODO: Should probably be moved into GenerateIterationHit
				if(FloatingData.ValidationMethod == EFloatingMovementValidateMethod::NoValidation)
				{
					PerformedFloatingHeight = GenerateFloatingIterationHit_NoValidation(IterationHit, IterationState);
			
					if(!PerformedFloatingHeight.IsSet())
					{
						// If the initial stepup failed, just do a regular iteration hit
						GenerateIterationHit(FloatingData, IterationState, IterationHit);
					}
				}
				else
				{
					// FLOATING: If we have validated our location, just run a regular iteration sweep
					// Generate the iteration hit
					GenerateIterationHit(FloatingData, IterationState, IterationHit);
				}

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

#if EDITOR
			MovementDevCheck(!PerformedFloatingHeight.IsSet(), "QUICK! Tell Filip! We never consumed our floating height! This could mean that we are still floating!");
#endif
			ConsumeFloatingHeight(true);

			// We are done
			if(!RunPrepareNextIteration())
				break;
		}
	}

	protected void HandleIterationDeltaMovementOnRemote()
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"HandleIterationDeltaMovementOnRemote");
#endif

		// We never prepare an iteration on remote, but we need to initialize the floating direction here
		FloatingDirection = GetFloatingDirection();
		check(FloatingDirection.IsNormalized());

		// On the remote side, we just move to the wanted location
		IterationState.DeltaToTrace = GenerateIterationDelta().Delta;
		FVector PendingLocation = IterationState.CurrentLocation + IterationState.DeltaToTrace;

		float CurrentGroundTraceDistance = GetGroundTraceDistance();

		// This is a grounded movement so we need to make sure that we find the ground.
		// So we add some extra trace distance in case the stepdown is not set correctly
		if(ShouldValidateRemoteSideGroundPosition())
			CurrentGroundTraceDistance += FloatingData.ShapeSizeForMovement;

		if(CurrentGroundTraceDistance > 0)
		{
			FMovementResolverGroundTraceSettings GroundTraceSettings;
			GroundTraceSettings.NormalForImpactTypeGenerationType = EMovementResolverNormalForImpactTypeGenerationType::ImpactNormal;
			GroundTraceSettings.bRedirectTraceIfInvalidGround = false;
			GroundTraceSettings.bFlatCapsuleBottom = FloatingData.bFlatCapsuleBottom;

			// We trace for the ground, using a sphere with the same amount as the capsule radius.
			// Since the networked replicated position might place us inside a shape,
			// We start the trace a bit higher up, but still inside the original shape,
			// making it possible to find the correct ground position.
			FHazeMovementTraceSettings TraceSettings = IterationTraceSettings;
			TraceSettings.OverrideTraceShape(FHazeTraceShape::MakeSphere(FloatingData.ShapeSizeForMovement));

			// Update the grounded impact with the remote trace
			IterationState.PhysicsState.GroundContact = QueryGroundShapeTrace(
				TraceSettings,
				PendingLocation, 
				-FloatingDirection * CurrentGroundTraceDistance, 
				CurrentWorldUp,
				GroundTraceSettings);

			// Use the impact for remote impact callbacks
			AccumulatedImpacts.AddImpact(IterationState.PhysicsState.GroundContact);
		}

		IterationState.ApplyMovement(1, PendingLocation);
	}

	FMovementHitResult QueryGroundShapeTrace(
		FHazeMovementTraceSettings TraceSettings,
		FVector StartLocation,
		FVector GroundTraceDelta,
		FVector WorldUp,
		FMovementResolverGroundTraceSettings GroundTraceSettings = FMovementResolverGroundTraceSettings()) const override
	{
		FMovementHitResult GroundHit = Super::QueryGroundShapeTrace(TraceSettings, StartLocation, GroundTraceDelta, WorldUp, GroundTraceSettings);
		//ApplyWalkOnEdgeGround(GroundHit, TraceSettings);
		return GroundHit;
	}

	/**
	 * When performing a ground trace, if we hit an edge, extend it out so that it is flat to prevent us following down edges
	 */
	protected void ApplyWalkOnEdgeGround(FMovementHitResult& GroundHit, FHazeMovementTraceSettings TraceSettings) const
	{
		if(FloatingData.EdgeHandling != EMovementEdgeHandlingType::Leave)
		{
			// Only apply walk on edge ground if we want to leave edges
			return;
		}

		if(!GroundHit.IsAnyGroundContact())
		{
			// We only extend ground edges
			return;
		}

		FPlane ImpactPlane = FPlane(GroundHit.ImpactPoint, FloatingDirection);
		FVector BottomOfShapeLocation = IterationState.ConvertLocationToShapeBottomLocation(GroundHit.Location, TraceSettings);
		if(ImpactPlane.PlaneDot(BottomOfShapeLocation) > 0)
		{
			// The bottom of the shape is above the edge, no need to adjust
			return;
		}

		BottomOfShapeLocation = BottomOfShapeLocation.PointPlaneProject(GroundHit.ImpactPoint, FloatingDirection);
		GroundHit.OverrideLocation(IterationState.ConvertShapeBottomLocationToCurrentLocation(BottomOfShapeLocation, TraceSettings));

#if !RELEASE
		ResolverTemporalLog.OverwriteMovementHit(GroundHit);
#endif
	}

	protected bool TryAlignWorldUpWithImpact(FMovementHitResult& Impact)
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"TryAlignWorldUpWithImpact");
#endif

		if(!ShouldAlignWorldUpWithContact(Impact))
			return false;
		
		const float AlignedStepDownSize = GetGroundTraceDistance();
		if(AlignedStepDownSize <= 0)
			return false;

		FVector PotentialNewWorldUp = Impact.ImpactNormal;
		if(FloatingData.EdgeHandling == EMovementEdgeHandlingType::Follow)
		{
			ApplyGroundEdgeInformation(Impact);
			if(Impact.IsOnAnEdge())
				PotentialNewWorldUp = Impact.Normal;
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
		const float BonusTrace = FloatingData.ShapeSizeForMovement * 0.1;

		// Use Impact Location because IterationState has not yet applied the movement
		AlignedState.CurrentLocation = Impact.Location + (PotentialNewWorldUp * BonusTrace);

		FHazeMovementTraceSettings AlignedTraceSettings = IterationTraceSettings;
		ChangeCurrentWorldUp(AlignedState, AlignedTraceSettings, PotentialNewWorldUp);

		FMovementResolverGroundTraceSettings GroundTraceSettings;
		GroundTraceSettings.NormalForImpactTypeGenerationType = EMovementResolverNormalForImpactTypeGenerationType::ImpactNormal;
		GroundTraceSettings.bResolveStartPenetrating = false;
		GroundTraceSettings.CustomTraceTag = n"NewWorldUpGround";
		GroundTraceSettings.bFlatCapsuleBottom = FloatingData.bFlatCapsuleBottom;

		FMovementHitResult AlignedGround = QueryGroundShapeTrace(
			AlignedTraceSettings, 
			AlignedState.CurrentLocation, 
			-PotentialNewWorldUp * (AlignedStepDownSize + BonusTrace),
			PotentialNewWorldUp,
			GroundTraceSettings);

		// This should be the new ground now,
		// else its not valid.
		if(!AlignedGround.IsAnyGroundContact())
			return false;

		// FLOATING: always apply ground edge information
		ApplyGroundEdgeInformation(AlignedGround);
		
		// Finalize the new grounded location
		AlignedState.CurrentLocation = AlignedGround.Location;

		IterationState = AlignedState;
		IterationTraceSettings = AlignedTraceSettings;

		// When Floating and aligning with ground, we want to maintain our velocity when hitting the ground coming from airborne
		bScopedKeepVelocityInRedirections = true;
		ApplyImpactOnDeltas(AlignedGround);
		bScopedKeepVelocityInRedirections = false;
		ChangeGroundedState(AlignedGround);
		ConsumeFloatingHeight(false);
		return true;
	}

	protected bool CanApplyGroundEdgeInformation(FMovementHitResult HitResult, bool bForceEvenIfSet = false) const
	{
		if(HitResult.EdgeResult.Type != EMovementEdgeType::Unset && !bForceEvenIfSet)
			return false;

		if(!HitResult.IsAnyGroundContact())
			return false;

		return true;
	}

	/** Applies the edge information to the movement hit result */
	protected void ApplyGroundEdgeInformation(FMovementHitResult& HitResult, bool bForceEvenIfSet = false) const
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"ApplyGroundEdgeInformation");
#endif

		if(!CanApplyGroundEdgeInformation(HitResult, bForceEvenIfSet))
			return;

		FVector MovementDirection = IterationState.GetHorizontalMovementDirection(CurrentWorldUp);
		if(MovementDirection.IsNearlyZero())
			 MovementDirection = IterationState.CurrentRotation.ForwardVector;

		const bool bFollowEdges = FloatingData.EdgeHandling == EMovementEdgeHandlingType::Follow;

		// If we are set to follow edges, and the angle between the impact normal and the normal is bigger than the walkable distance,
		// we call this and edge directly
		float AngleBetweenNormals = HitResult.Normal.GetAngleDegreesTo(HitResult.ImpactNormal);
		if(bFollowEdges && AngleBetweenNormals > FloatingData.WalkableSlopeAngle)
		{
			FMovementEdge& EdgeInfo = HitResult.EdgeResult;
			EdgeInfo.Type = EMovementEdgeType::Edge;
			EdgeInfo.Distance = 0;
			EdgeInfo.EdgeNormal = HitResult.Normal;
		}
		// Else we trace for an edge the normal way
		else
		{
			HitResult.EdgeResult = GetEdgeInformation(HitResult, MovementDirection, EMovementEdgeNormalRedirectType::None);	
			FMovementEdge& EdgeInfo = HitResult.EdgeResult;

			if(EdgeInfo.IsEdge())
			{
				if(bFollowEdges)
				{
					EdgeInfo.bIsOnEmptySideOfLedge = false;
					EdgeInfo.bMovingPastEdge = false;
					EdgeInfo.EdgeNormal = HitResult.Normal;
				}
			}
		}

		if(HitResult.EdgeResult.IsEdge())
		{
			if(HitResult.EdgeResult.bMovingPastEdge)
			{
				// FLOATING: When moving over an edge, use the edge normal
				HitResult.OverrideNormals(HitResult.EdgeResult.GroundNormal, HitResult.EdgeResult.GroundNormal);
			}
			else if(HitResult.EdgeResult.bIsOnEmptySideOfLedge)
			{
				// FLOATING: When going over an edge from the outside in, keep the normal pointed in the impact normal direction to prevent pinging off
				HitResult.OverrideNormals(HitResult.ImpactNormal, HitResult.ImpactNormal);
			}
		}

#if !RELEASE
		// After modifying the movement hit, we must overwrite the temporal log value
		ResolverTemporalLog.OverwriteMovementHit(HitResult);
#endif
	}

	/**
	 * This function will change the pending delta moves
	 */
	protected void ApplyImpactOnDeltas(FMovementHitResult Impact)
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"ApplyImpactOnDeltas");
#endif

		// You have to have control over when to redirect and when to not do it
		if(!devEnsure(Impact.IsValidBlockingHit(), f"The component {Impact.Component} with actor {Impact.Actor} at location {Impact.ImpactPoint} is not valid for movement. BSPs are not supported any more."))
			Debug::DrawDebugSphere(Impact.ImpactPoint, Math::Min(Impact.Component.Bounds.SphereRadius, 400), LineColor = FLinearColor::Red, Thickness = 6, Duration = 10);

		const FMovementHitResult& GroundedState = IterationState.PhysicsState.GroundContact;
		const bool bApplyRedirect = ShouldProjectMovementOnImpact(Impact);

		for(auto It : IterationState.DeltaStates)
		{
			FMovementDelta MovementDelta = It.Value.ConvertToDelta();
			if(MovementDelta.IsNearlyZero())
				continue;

			if(bApplyRedirect)
				MovementDelta = ProjectMovementUponImpact(MovementDelta, Impact, GroundedState);
			else
				MovementDelta = FMovementDelta();

#if !RELEASE
			ResolverTemporalLog.MovementDelta(f"New {It.Key:n}", IterationState.CurrentLocation, MovementDelta, InColor = FLinearColor::Green);
			ResolverTemporalLog.MovementDelta(f"Previous {It.Key:n}", IterationState.CurrentLocation, It.Value.ConvertToDelta());
#endif

			IterationState.OverrideDelta(It.Key, MovementDelta);
		}
	}

	protected bool ShouldProjectMovementOnImpact(FMovementHitResult Impact) const
	{
		if(Impact.IsWallImpact())
		{
			return FloatingData.bRedirectMovementOnWallImpacts;
		}
		else if(Impact.IsCeilingImpact())
		{
			return FloatingData.bRedirectMovementOnCeilingImpacts;
		}
		else if(Impact.IsAnyGroundContact())
		{
			return FloatingData.bRedirectMovementOnGroundImpacts;
		}
		else
		{
			return false;
		}
	}

	/**
	 * Project a MovementDelta upon an impact.
	 * Consider overriding ProjectDeltaUpon[...] functions in child resolvers to change the behaviour instead of this function.
	 */
	protected FMovementDelta ProjectMovementUponImpact(
		FMovementDelta DeltaState,
		FMovementHitResult Impact,
		FMovementHitResult GroundedState) const
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
				return ProjectDeltaUponFloorImpact(DeltaState, Impact, GroundedState);
			}
			else
			{
				return ProjectDeltaUponGroundedBlockingImpact(DeltaState, Impact, GroundedState);
			}
		}
		else
		{
			if(bHitCanBeGround)
			{
				return ProjectDeltaUponLandingImpact(DeltaState, Impact, GroundedState);
			}
			else
			{
				return ProjectDeltaUponGenericImpact(DeltaState, Impact, GroundedState);
			}
		}
	}

	/**
	 * Floor Impact
	 * We are grounded, and the impact is also ground.
	 */
	FMovementDelta ProjectDeltaUponFloorImpact(FMovementDelta DeltaState, FMovementHitResult Impact, FMovementHitResult GroundedState) const
	{
		// FLOATING: Always use impact normal when using floating movement, to prevent jumping up edges
		FVector DeltaRedirectNormal = Impact.ImpactNormal;

		if(Impact.IsOnAnEdge())
			DeltaRedirectNormal = Impact.EdgeResult.GroundNormal;

		// Only redirect delta if it goes into the ground
		const bool bRedirectDelta = DeltaState.Delta.DotProduct(DeltaRedirectNormal) < 0;
		const bool bRedirectVelocity = DeltaState.Velocity.DotProduct(DeltaRedirectNormal) < 0;

		if(!bRedirectDelta && !bRedirectVelocity)
			return DeltaState;

		// We redirect the delta without any loss.
		FMovementDelta ConstrainedDeltaState = DeltaState.GetHorizontalPart(DeltaRedirectNormal);
		ConstrainedDeltaState = ConstrainedDeltaState.SurfaceProject(DeltaRedirectNormal, CurrentWorldUp);

		if(!bRedirectDelta)
			ConstrainedDeltaState.Delta = DeltaState.Delta;

		if(!bRedirectVelocity)
			ConstrainedDeltaState.Velocity = DeltaState.Velocity;
		
		return ConstrainedDeltaState;
	}

	/**
	 * Grounded Blocking Impact
	 * We are grounded, but hit unwalkable ground, a wall or ceiling.
	 */
	FMovementDelta ProjectDeltaUponGroundedBlockingImpact(FMovementDelta DeltaState, FMovementHitResult Impact, FMovementHitResult GroundedState) const
	{
		// On blocking hits, project the movement on the obstruction while following the grounding plane
		// Generate a correct impact normal along the grounded surface
		const FVector GroundNormal = GroundedState.Normal;
		const FVector ImpactNormal = Impact.Normal.GetImpactNormalProjectedAlongSurface(GroundNormal, CurrentWorldUp);

		const FVector ObstructionRightAlongGround = ImpactNormal.CrossProduct(GroundNormal).GetSafeNormal();
		const FVector ObstructionUpAlongGround = ObstructionRightAlongGround.CrossProduct(ImpactNormal).GetSafeNormal(ResultIfZero = GroundNormal);

		FMovementDelta ConstrainedDeltaState = DeltaState.SurfaceProject(ObstructionUpAlongGround, CurrentWorldUp);
		return ConstrainedDeltaState.PlaneProject(ImpactNormal);
	}

	/**
	 * Landing Impact
	 * We are airborne, but hit walkable ground.
	 */
	FMovementDelta ProjectDeltaUponLandingImpact(FMovementDelta DeltaState, FMovementHitResult Impact, FMovementHitResult GroundedState) const
	{
		FMovementDelta ConstrainedDeltaState = DeltaState.PlaneProject(CurrentWorldUp, bScopedKeepVelocityInRedirections);

		FVector ImpactNormal = Impact.Normal;
		if(Impact.IsOnAnEdge())
		{
			ImpactNormal = Impact.ImpactNormal;
		}

		// adding ground friction will remove the vertical part of the movement since we moved into the ground
		ConstrainedDeltaState = ConstrainedDeltaState.GetHorizontalPart(Impact.Normal);
		return ConstrainedDeltaState.SurfaceProject(Impact.Normal, CurrentWorldUp);
	}

	/**
	 * Generic Impact
	 * We are airborne, and hit unwalkable ground, a wall or ceiling.
	 */
	FMovementDelta ProjectDeltaUponGenericImpact(FMovementDelta DeltaState, FMovementHitResult Impact, FMovementHitResult GroundedState) const
	{
		return DeltaState.PlaneProject(Impact.Normal);
	}

	protected bool CanPerformGroundTrace() const
	{
		if(!FloatingData.bCanPerformGroundTrace)
			return false;

		// FLOATING: Always perform ground tracing (to remove the floating)
		// But instead, we don't trace as far if leaving ground
		// @see GetGroundTraceDistance()
		// if(IsLeavingGround())
		// 	return false;

		// FLOATING: Only perform ground trace if we have any trace distance
		if(GetGroundTraceDistance() < KINDA_SMALL_NUMBER)
			return false;

		return true;
	}

	protected bool IsLeavingGround() const
	{
		if(ShouldValidateRemoteSideGroundPosition())
			return false;

		if(bStickToGround && IterationState.PhysicsState.GroundContact.IsAnyGroundContact())
			return false;

		// Impulse always makes us leave
		FMovementDelta Impulse = IterationState.GetDelta(EMovementIterationDeltaStateType::Impulse);
		if(Impulse.Delta.DotProduct(CurrentWorldUp) > KINDA_SMALL_NUMBER)
			return true;

		return false;
	}

	protected float GetGroundTraceDistance() const
	{
		float GroundTraceDistance = VerticalDeltaGroundTraceDistance + FloatingData.SafetyDistance.Y + 0.125;

		// FLOATING: We still do ground traces even when we are leaving ground, but we only perform it to undo the floating height
		if(IsLeavingGround())
			GroundTraceDistance = 0;
	
		// FLOATING: Add the floating height to the ground trace distance
		if(PerformedFloatingHeight.IsSet())
			GroundTraceDistance += PerformedFloatingHeight.Value;

		return GroundTraceDistance;
	}

	// Floating data only uses the normal to determine what kind of impact this is
	FVector GetNormalForImpactTypeGeneration(FHitResult HitResult) const override
	{
		return HitResult.Normal;
	}

	bool ShouldAlignWorldUpWithGround() const override
	{
		return FloatingData.AlignWithImpactSettings.bAlignWithGround;
	}

	bool ShouldAlignWorldUpWithWall() const override
	{
		return FloatingData.AlignWithImpactSettings.bAlignWithWall;
	}

	bool ShouldAlignWorldUpWithCeiling() const override
	{
		return FloatingData.AlignWithImpactSettings.bAlignWithCeiling;
	}

	protected const FVector& GetCurrentWorldUp() const property override
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
		FMovementDelta PreviousDelta = State.GetDelta(EMovementIterationDeltaStateType::Movement);
#endif

		State.ChangeDeltaWorldUp(EMovementIterationDeltaStateType::Movement, NewWorldUp);

#if !RELEASE
		ResolverTemporalLog.MovementDelta("New Delta", IterationState.CurrentLocation, State.GetDelta(EMovementIterationDeltaStateType::Movement), InColor = FLinearColor::Green);
		ResolverTemporalLog.MovementDelta("Previous Delta", IterationState.CurrentLocation, PreviousDelta);
#endif

		State.CurrentRotation = FinalizeRotation(State.CurrentRotation, NewWorldUp);
		TraceSettings.UpdateRotation(State.CurrentRotation);
	}

	/**
	 * FLOATING
	 * These functions are specifically for the Floating movement
	 */

	protected float GetFloatingHeight() const
	{
		return FloatingData.FloatingHeight;
	}

	protected void ConsumeFloatingHeight(bool bApplyOnCurrentLocation) 
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"ConsumeFloatingHeight");
#endif

		if(!PerformedFloatingHeight.IsSet())
			return;

#if !RELEASE
		ResolverTemporalLog.Value("PerformedFloatingHeight", PerformedFloatingHeight.Value);
		ResolverTemporalLog.Value("bApplyOnCurrentLocation", bApplyOnCurrentLocation);
		ResolverTemporalLog.MovementShape("Location", IterationState.CurrentLocation, IterationTraceSettings);
#endif

		if(bApplyOnCurrentLocation)
		{
			IterationState.CurrentLocation -= (FloatingDirection * PerformedFloatingHeight.Value);

#if !RELEASE
		ResolverTemporalLog.MovementShape("Applied Location", IterationState.CurrentLocation, IterationTraceSettings);
#endif
		}
		
		PerformedFloatingHeight.Reset();
	}

	/**
	 * Get the direction we want to apply our floating height in.
	 */
	protected FVector GetFloatingDirection() const
	{
		switch(FloatingData.FloatingDirection)
		{
			case EFloatingMovementFloatingDirection::WorldUp:
				return CurrentWorldUp;

			case EFloatingMovementFloatingDirection::Normal:
			{
				if(IterationState.PhysicsState.GroundContact.IsAnyGroundContact())
				{
					if(FloatingData.EdgeHandling == EMovementEdgeHandlingType::Leave && IterationState.PhysicsState.GroundContact.IsOnAnEdge())
						return IterationState.PhysicsState.GroundContact.EdgeResult.GroundNormal;
					else
						return IterationState.PhysicsState.GroundContact.Normal;
				}
				else
				{
					return CurrentWorldUp;
				}
			}

			case EFloatingMovementFloatingDirection::ImpactNormal:
			{
				if(IterationState.PhysicsState.GroundContact.IsAnyGroundContact())
				{
					if(FloatingData.EdgeHandling == EMovementEdgeHandlingType::Leave && IterationState.PhysicsState.GroundContact.IsOnAnEdge())
						return IterationState.PhysicsState.GroundContact.EdgeResult.GroundNormal;
					else
						return IterationState.PhysicsState.GroundContact.ImpactNormal;
				}
				else
				{
					return CurrentWorldUp;
				}
			}

			case EFloatingMovementFloatingDirection::ActorUp:
				return IterationState.CurrentRotation.UpVector;

			case EFloatingMovementFloatingDirection::GravityUp:
				return -GetGravityDirection();

			case EFloatingMovementFloatingDirection::Explicit:
				return FloatingData.ExplicitFloatingDirection;
		}
	}

	/**
	 * No validation that the floating location is valid.
	 * Just move the current location up, run an iteration sweep, then move the location back down.
	 * If we are penetrating something, this will fail and should revert back to the previous state.
	 * @return StepUpSize. If not set, the iteration failed.
	 */
	protected TOptional<float> GenerateFloatingIterationHit_NoValidation(FMovementHitResult& IterationHit, FMovementResolverState& State)
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"GenerateFloatingIterationHit_NoValidation");
#endif

		if(!ensure(FloatingData.ValidationMethod == EFloatingMovementValidateMethod::NoValidation))
			return TOptional<float>();
				
		// if(IsLeavingGround())
		// 	return TOptional<float>();
				
		// if(!State.PhysicsState.GroundContact.IsAnyGroundContact())
		// 	return TOptional<float>();
				
		const float StepUpSize = GetFloatingHeight();
		if(StepUpSize <= 0)
			return TOptional<float>();
				
		const FVector StepUpDelta = FloatingDirection * StepUpSize;
		const FVector StepUpLocation = State.CurrentLocation + StepUpDelta;

		const FVector PreviousCurrentLocation = State.CurrentLocation;
		State.CurrentLocation = StepUpLocation;

		GenerateIterationHit(FloatingData, State, IterationHit, n"Floating GenerateIterationHit NoValidation");

		if(IterationHit.bStartPenetrating)
		{
			State.CurrentLocation = PreviousCurrentLocation;
			return TOptional<float>();
		}

		return TOptional<float>(StepUpSize);
	}

	/**
	 * Validate that the floating location is non-colliding by doing a overlap
	 * at the floating location.
	 * If the overlap finds anything, we simply don't do the floating sweep
	 * and stay on the ground instead.
	 * Note: Only supported with capsules.
	 */
	protected TOptional<float> ValidateFloating_Overlap(FVector& CurrentLocation) const
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"ValidateFloating_Overlap");
#endif

		if(!ensure(FloatingData.ValidationMethod == EFloatingMovementValidateMethod::ValidateOverlap))
			return TOptional<float>();

		// if(IsLeavingGround())
		// 	return TOptional<float>();

		// if(!IterationState.PhysicsState.GroundContact.IsAnyGroundContact())
		// 	return TOptional<float>();

		const float StepUpSize = GetFloatingHeight();
		if(StepUpSize <= 0)
			return TOptional<float>();
				
		auto CollisionShape = FloatingData.GetCollisionShape();
		if(!ensure(CollisionShape.IsCapsule(), "Only capsule is supported with this validation!"))
			return TOptional<float>();
		
		// If the step up size is larger than the flat area of a capsule, then we could miss things with a vertical step up overlap
		const float FlatSideHeight = (CollisionShape.Shape.CapsuleHalfHeight - CollisionShape.Shape.CapsuleRadius) * 2;
		if(!ensure(StepUpSize < FlatSideHeight))
			return TOptional<float>();

		const FVector StepUpDelta = FloatingDirection * StepUpSize;
		const FVector StepUpLocation = IterationState.CurrentLocation + StepUpDelta;

		FOverlapResultArray Overlaps = QueryOverlaps(StepUpLocation, FHazeTraceTag(n"Floating InitialStepUp Overlap"));
		if(Overlaps.HasBlockHit())
			return TOptional<float>();
				
		CurrentLocation = StepUpLocation;

		return TOptional<float>(StepUpSize);
	}

	/**
	 * Validate that the floating location is non-colliding by doing a sweep
	 * up from the current location to the target height.
	 * If we collide with something, we change the floating height to the collision height.
	 */
	protected TOptional<float> ValidateFloating_SweepUp(FVector& CurrentLocation) const
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"ValidateFloating_SweepUp");
#endif

		if(!ensure(FloatingData.ValidationMethod == EFloatingMovementValidateMethod::ValidateSweep))
			return TOptional<float>();
			
		if(IsLeavingGround())
			return TOptional<float>();
				
		if(!IterationState.PhysicsState.GroundContact.IsAnyGroundContact())
			return TOptional<float>();
				
		const float StepUpSize = GetFloatingHeight();
		if(StepUpSize <= 0)
			return TOptional<float>();
				
		const FVector StepUpDelta = FloatingDirection * StepUpSize;

		FMovementHitResult StepUpHit = QueryShapeTrace(
			IterationState.CurrentLocation, 
			StepUpDelta, 
			FHazeTraceTag(n"Floating InitialStepUp SweepUp"));

		if(StepUpHit.bStartPenetrating)
			return TOptional<float>();
				
		if(StepUpHit.Time == 0)
			return TOptional<float>();
				
		if(StepUpHit.IsValidBlockingHit())
		{
			CurrentLocation = StepUpHit.Location;
			return TOptional<float>(StepUpHit.Distance);
		}
		else
		{
			CurrentLocation += StepUpDelta;
			return TOptional<float>(StepUpSize);
		}
	}
};