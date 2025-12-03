/**
 * Simple movement should be used by moves that only requires a single redirect or is just by a lot of actors that need to be performant, like AIs.
 * It has very limited settings and only performs the most basic collision redirect. It only handles velocity and impulses.
 */
class USimpleMovementResolver : UBaseMovementResolver
{
	default RequiredDataType = USimpleMovementData;
	private const USimpleMovementData SimpleMovementData;
	
	float VerticalDeltaGroundTraceDistance = 0;
	bool bIterationIsSquished = false;
	TOptional<float> PerformedFloatingHeight;

	void PrepareResolver(const UBaseMovementData Movement) override
	{
		Super::PrepareResolver(Movement);

#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"PrepareResolver");
#endif

		SimpleMovementData = Cast<USimpleMovementData>(Movement);
		IterationState.InitFromMovementData(SimpleMovementData);
		bIterationIsSquished = false;
		PerformedFloatingHeight.Reset();
	}

#if EDITOR
	void ResolveRerun() override
	{
		check(SimpleMovementData != nullptr);
		
		Resolve();
		PostResolve();

		// Did the rerun succeed
		check(SimpleMovementData.DebugFinalTransform.Equals(FTransform(IterationState.CurrentRotation, IterationState.CurrentLocation)));
	}
#endif

	void ResolveAndApplyMovementRequest(UHazeMovementComponent MovementComponent) override
	{
#if !RELEASE
	 	check(SimpleMovementData != nullptr);
		check(!MovementComponent.IsApplyingInParallel());
#endif

		// In the editor, we add the rerun each movement frame
#if EDITOR
		USimpleMovementData RerunData = Cast<USimpleMovementData>(MovementComponent.AddRerunData(SimpleMovementData, this));
#endif

		// Temporal log the first iteration state
#if !RELEASE
		MovementDebug::AddInitialDebugInfo(MovementComponent, SimpleMovementData, this);
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

		// Temporal log the final state
#if !RELEASE
		MovementDebug::AddMovementResolvedState(
			MovementComponent,
			SimpleMovementData,
			this,
			IterationState,
			SimpleMovementData.IterationTime
		);	
#endif
	}

	void PostResolve() override
	{
		Super::PostResolve();
	}

	void StopResolving() override
	{
		Super::StopResolving();
		
		IterationState.PerformedMovementAlpha = 1.0;
	}

	UFUNCTION(BlueprintOverride)
	protected void ApplyResolve(UHazeMovementComponentBase MovementComponent) final
	{
		// Add all the data collected in the slide
		MovementComponent.SetMovingStatus(true, SimpleMovementData.StatusInstigator);
		auto MoveComp = Cast<UHazeMovementComponent>(MovementComponent);
		ApplyResolvedData(MoveComp);
		PostApplyResolvedData(MoveComp);
		MovementComponent.SetMovingStatus(false, SimpleMovementData.StatusInstigator);
	}

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
		// Set the current grounded state to the last grounded state
		// and prepare the vertical trace delta
		if (IterationCount == 1)
		{
			PrepareFirstIteration();
		}

		// Trace the delta and handle potential overlap
		IterationState.DeltaToTrace = GenerateIterationDelta().Delta;
		
		if(IterationState.DeltaToTrace.IsNearlyZero(IterationTraceSettings.TraceLengthClamps.Min))
		{
			IterationState.DeltaToTrace = FVector::ZeroVector;
			return false;
		}

		if(IterationCount > SimpleMovementData.MaxRedirectIterations)
			return false;

		if(IterationState.RemainingMovementAlpha < SMALL_NUMBER)
			return false;

		return true;
	}

	protected void PrepareFirstIteration()
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"PrepareFirstIteration");
#endif

		if(CanPerformGroundTrace())
		{
			const FVector PendingDelta = GenerateIterationDelta().Delta;
			FMovementHitResult InitialGround = SimpleMovementData.OriginalContacts.GroundContact;

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
				IterationState.PhysicsState.GroundContact = InitialGround;

				// if our velocity is pointing down into the ground
				// we start with redirecting against the ground
				if(VerticalDeltaGroundTraceDistance > 0)
					ApplyImpactOnDeltas(InitialGround);

				// If we are actually trying to leave an edge,
				// we don't apply the ground stickyness.
				// This might be added as a separate setting but the wanted behavior
				// is that you always "fly" out over edges  
				if(!IsLeavingEdge(InitialGround))
				{
					VerticalDeltaGroundTraceDistance += SimpleMovementData.SafetyDistance.Y;
				}	
			}
		}

		// if(!IsLeavingGround() && SimpleMovementData.bCanPerformGroundTrace)
		// {
		// 	// The vertical velocity is going to be removed so we convert it into ground trace distance instead
		// 	VerticalDeltaGroundTraceDistance = Math::Max(IterationState.DeltaToTrace.DotProduct(-CurrentWorldUp), 0);

		// 	// If we used to be grounded, we start by tracing for the ground to see if we still are grounded
		// 	if(SimpleMovementData.OriginalContacts.GroundContact.IsValidBlockingHit())
		// 	{	
		// 		VerticalDeltaGroundTraceDistance += SimpleMovementData.SafetyDistance.Y;

		// 		FMovementResolverGroundTraceSettings Settings;
		// 		Settings.bRedirectTraceIfInvalidGround = false;
		// 		Settings.CustomTraceTag = n"InitialGroundTrace";
		// 		IterationState.PhysicsState.GroundContact = QueryGroundShapeTrace(
		// 			IterationState.CurrentLocation,  
		// 			-CurrentWorldUp * (SimpleMovementData.SafetyDistance.Y + KINDA_SMALL_NUMBER), 
		// 			Settings);
		// 	}
		// }
	}

	protected void FinalizeGroundedState(bool&out bOutSnappedToGround)
	{
		const float GroundTraceDistanceToPerform = GetGroundTraceDistance();

		// Finalize the ground contact if we haven't done so
		if(GroundTraceDistanceToPerform > 0.0)
		{
			FMovementHitResult PendingGroundContact = QueryGroundShapeTrace(
				IterationState.CurrentLocation, 
				-CurrentWorldUp * GroundTraceDistanceToPerform
				);

			if(PendingGroundContact.IsValidBlockingHit())
				HandleMovementImpactInternal(PendingGroundContact, EMovementResolverAnyShapeTraceImpactType::Ground);

			// If the final trace is a ground contact, use that
			if(PendingGroundContact.IsAnyGroundContact())
			{
				IterationState.CurrentLocation = PendingGroundContact.Location;
				IterationState.PhysicsState.GroundContact = PendingGroundContact;
				bOutSnappedToGround = true;
			}	
			else
			{
				IterationState.PhysicsState.GroundContact = FMovementHitResult();
				bOutSnappedToGround = false;
			}	
		}
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
			return;

		IterationState.ApplyMovement(MovementHit.Time, MovementHit.Location);
		IterationState.PhysicsState.GroundContact = MovementHit;	
		ApplyImpactOnDeltas(MovementHit);
	}

	protected void HandleIterationDeltaMovementWallImpact(FMovementHitResult& MovementHit)
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"HandleIterationDeltaMovementWallImpact");
#endif

		check(MovementHit.Type == EMovementImpactType::Wall);

		if(HandleMovementImpactInternal(MovementHit, EMovementResolverAnyShapeTraceImpactType::Iteration))
			return;

		IterationState.ApplyMovement(MovementHit.Time, MovementHit.Location);

		bool bSnappedToGround = false;
		FinalizeGroundedState(bSnappedToGround);

		ConsumeFloatingHeight(!bSnappedToGround);
		
		IterationState.PhysicsState.WallContact = MovementHit;

		ApplyImpactOnDeltas(MovementHit);
	}

	protected void HandleIterationDeltaMovementCeilingImpact(FMovementHitResult& MovementHit)
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"HandleIterationDeltaMovementCeilingImpact");
#endif

		check(MovementHit.Type == EMovementImpactType::Ceiling);

		if(HandleMovementImpactInternal(MovementHit, EMovementResolverAnyShapeTraceImpactType::Iteration))
			return;

		IterationState.ApplyMovement(MovementHit.Time, MovementHit.Location);
		IterationState.PhysicsState.CeilingContact = MovementHit;
		ApplyImpactOnDeltas(MovementHit);
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

		bool bSnappedToGround = false;
		FinalizeGroundedState(bSnappedToGround);
		ConsumeFloatingHeight(!bSnappedToGround);
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
				FMovementHitResult IterationHit;
				while(true)
				{
					if(SimpleMovementData.FloatingHeight > 0)
					{
						// Move us up, floating over the surface
						PerformedFloatingHeight.Set(SimpleMovementData.FloatingHeight);
						IterationState.CurrentLocation += IterationState.WorldUp * SimpleMovementData.FloatingHeight;
					}

					// Generate the movement hit result from the current directed movement delta
					const FHazeTraceTag TraceTag = GenerateTraceTag(n"Movement", n"HandleIterationDeltaMovementOnControl");
					IterationHit = QueryShapeTrace(
						IterationState.CurrentLocation, 
						IterationState.DeltaToTrace, 
						TraceTag);

					// This is a valid trace
					if(!IterationHit.bStartPenetrating)
						break;
					
					if(IterationDepenetrationCount >= SimpleMovementData.MaxDepenetrationIterations)
						break;

					if(PreResolveStartPenetrating(IterationHit))
						continue;

					IterationState.CurrentLocation = ResolveStartPenetrating(IterationHit);
					IterationDepenetrationCount += 1;
				}

				// BAD iteration. We could not get out and are now stuck
				if(IterationHit.bStartPenetrating)
				{
					bIterationIsSquished = true;
					ConsumeFloatingHeight();
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

			// we have ended upp inside something and can't move anymore
			if(bIterationIsSquished)
				break;

			ConsumeFloatingHeight();
			
			// We are done
			if(!RunPrepareNextIteration())
				break; 
		}

#if !RELEASE
		check(!PerformedFloatingHeight.IsSet(), "We never consumed the floating height!");
#endif
	}

	protected void HandleIterationDeltaMovementOnRemote()
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"HandleIterationDeltaMovementOnRemote");
#endif

		// On the remote side, we just move to the wanted location
		IterationState.DeltaToTrace = GenerateIterationDelta().Delta;
		IterationState.ApplyMovement(1);
		
		if(ShouldValidateRemoteSideGroundPosition())
		{
			FMovementResolverGroundTraceSettings Settings;
			Settings.NormalForImpactTypeGenerationType = EMovementResolverNormalForImpactTypeGenerationType::ImpactNormal;
			Settings.bRedirectTraceIfInvalidGround = false;

			// We trace for the ground, using a sphere with the same amount as the capsule radius.
			// Since the networked replicated position might place us inside a shape,
			// We start the trace a bit higher up, but still inside the original shape,
			// making it possible to find the correct ground position.
			FHazeMovementTraceSettings TraceSettings = IterationTraceSettings;
			TraceSettings.OverrideTraceShape(FHazeTraceShape::MakeSphere(SimpleMovementData.ShapeSizeForMovement));
			
			// Since the capsule might be offset from the feet location,
			// we need to add that offset into the trace length
			float TraceLength = SimpleMovementData.ShapeSizeForMovement * 2;

			IterationState.PhysicsState.GroundContact = QueryGroundShapeTrace(
				TraceSettings,
				IterationState.CurrentLocation, 
				-CurrentWorldUp * TraceLength, 
				CurrentWorldUp,
				Settings);

			// Use the impact for remote impact callbacks
			AccumulatedImpacts.AddImpact(IterationState.PhysicsState.GroundContact);
		}
	}

	// Sliding data only uses the normal to determine what kind of impact this is
	protected FVector GetNormalForImpactTypeGeneration(FHitResult HitResult) const override
	{
		return HitResult.Normal;
	}

	/**
	 * This function will change the pending delta moves
	 */
	protected void ApplyImpactOnDeltas(FMovementHitResult Impact)
	{
		// You have to have control over when to redirect and when to not do it
		if(!devEnsure(Impact.IsValidBlockingHit(), f"The component {Impact.Component} with actor {Impact.Actor} at location {Impact.ImpactPoint} is not valid for movement. BSPs are not supported any more."))
			Debug::DrawDebugSphere(Impact.ImpactPoint, Math::Min(Impact.Component.Bounds.SphereRadius, 400), LineColor = FLinearColor::Red, Thickness = 6, Duration = 10);
	
		const FMovementHitResult& GroundedState = IterationState.PhysicsState.GroundContact;

		for(auto It : IterationState.DeltaStates)
		{
			FMovementDelta MovementDelta = It.Value.ConvertToDelta();
			if(MovementDelta.IsNearlyZero())
				continue;

			MovementDelta = ProjectMovementUponImpact(MovementDelta, Impact, GroundedState);
			IterationState.OverrideDelta(It.Key, MovementDelta);
		}
	}

	protected FMovementDelta ProjectMovementUponImpact(FMovementDelta DeltaState, FMovementHitResult Impact, FMovementHitResult GroundedState) const
	{
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
		// If we are on edges, we use the impact normal instead to not get sucked down
		FVector ImpactNormal = Impact.Normal;
		if(IsLeavingEdge(Impact))
			ImpactNormal = Impact.ImpactNormal;

		// We redirect the delta without any loss.
		return DeltaState.PlaneProject(ImpactNormal, SimpleMovementData.bMaintainMovementSizeOnGroundedRedirects);
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
		return DeltaState.PlaneProject(Impact.Normal, SimpleMovementData.bMaintainMovementSizeOnGroundedRedirects);
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
		if(!SimpleMovementData.bCanPerformGroundTrace)
			return false;

		if(IsLeavingGround())
			return false;

		return true;
	}

	protected bool IsLeavingGround() const
	{
		const FVector Impulse = IterationState.GetDelta(EMovementIterationDeltaStateType::Impulse).Delta;
		if(Impulse.DotProduct(CurrentWorldUp) > KINDA_SMALL_NUMBER)
			return true;

		if(!SimpleMovementData.bCanPerformGroundTrace)
			return true;

		return false;
	}

	protected float GetGroundTraceDistance() const
	{
		if(!SimpleMovementData.bCanPerformGroundTrace)
			return 0;

		float GroundTraceDistance = VerticalDeltaGroundTraceDistance;
		
		if(PerformedFloatingHeight.IsSet())
			GroundTraceDistance += PerformedFloatingHeight.Value;

		return GroundTraceDistance;
	}

	const FVector& GetCurrentWorldUp() const property override
	{
		return IterationState.WorldUp;
	}

	protected float GetFloatingHeight() const
	{
		return SimpleMovementData.FloatingHeight;
	}

	protected void ConsumeFloatingHeight(bool bApplyOnCurrentLocation = true) 
	{
		if(!PerformedFloatingHeight.IsSet())
			return;

		if(bApplyOnCurrentLocation)
			IterationState.CurrentLocation -= (IterationState.WorldUp * PerformedFloatingHeight.Value);
		
		PerformedFloatingHeight.Reset();
	}
}