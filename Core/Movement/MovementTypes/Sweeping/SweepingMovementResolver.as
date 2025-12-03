/**
 * Sweeping movement should used by actors moving like a physical object. (Like a ball).
 * It is also good for flying objects or moves that should follow a surface as if it was a ball.
 */
class USweepingMovementResolver : UBaseMovementResolver
{
	default RequiredDataType = USweepingMovementData;
	private const USweepingMovementData SweepingData;

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
		SweepingData = Cast<USweepingMovementData>(Movement);

		Super::PrepareResolver(Movement);

#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"PrepareResolver");
#endif

		IterationState.InitFromMovementData(SweepingData);
		IterationState.CurrentRotation = FinalizeRotation(IterationState.CurrentRotation, CurrentWorldUp);
		IterationTraceSettings.UpdateRotation(IterationState.CurrentRotation);
		bIterationIsSquished = false;
		bPerformSubStep = false;
		MaxSubStepTraceLength = 0;
		VerticalDeltaGroundTraceDistance = 0;
		bStickToGround = false;

		// This requires us to sub step the movement so we detect an edge when it actually happens
		if(SweepingData.bAllowSubStep && CanPerformGroundTrace() 
			&& SweepingData.OriginalContacts.GroundContact.IsAnyGroundContact()
			&& (SweepingData.EdgeHandling == EMovementEdgeHandlingType::Stop || SweepingData.AlignWithImpactSettings.IsActive()))
		{
			bPerformSubStep = true;
			MaxSubStepTraceLength = Math::Max(SweepingData.ShapeSizeForMovement - SweepingData.SafetyDistance.X, 1);
			BonusSubStepIterations = SweepingData.MaxRedirectIterations;

#if !RELEASE	
			if(SweepingData.EdgeHandling == EMovementEdgeHandlingType::Stop)
				PerformSubStepReason = "EdgeHandling == Stop";
			else if(SweepingData.AlignWithImpactSettings.IsActive())
				PerformSubStepReason = "Align With Impact";
			DebugValidateMoveAmount(GenerateIterationDelta().Delta, MaxSubStepTraceLength, BonusSubStepIterations, PerformSubStepReason);
#endif
		}
	}

#if EDITOR
	void ResolveRerun() override
	{
		check(SweepingData != nullptr);

		Resolve();
		PostResolve();

		// Did the rerun succeed
		check(SweepingData.DebugFinalTransform.Equals(FTransform(IterationState.CurrentRotation, IterationState.CurrentLocation)));
	}
#endif

	void ResolveAndApplyMovementRequest(UHazeMovementComponent MovementComponent) override
	{
#if !RELEASE
	 	check(SweepingData != nullptr);
		check(!MovementComponent.IsApplyingInParallel());
#endif

#if EDITOR
		// In the editor, we add the rerun each movement frame
		USweepingMovementData RerunData = Cast<USweepingMovementData>(MovementComponent.AddRerunData(SweepingData, this));
#endif

#if !RELEASE
		// Temporal log the first iteration state
		MovementDebug::AddInitialDebugInfo(MovementComponent, SweepingData, this);
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
			SweepingData,
			this,
			IterationState,
			SweepingData.IterationTime
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
		MovementComponent.SetMovingStatus(true, SweepingData.StatusInstigator);
		auto MoveComp = Cast<UHazeMovementComponent>(MovementComponent);
		ApplyResolvedData(MoveComp);
		PostApplyResolvedData(MoveComp);
		MovementComponent.SetMovingStatus(false, SweepingData.StatusInstigator);
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

		if(IterationCount > SweepingData.MaxRedirectIterations)
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

		// The sweeping data don't support edge stopping at the movement
		check(SweepingData.EdgeHandling != EMovementEdgeHandlingType::Stop);

		// We start with fixing the current ground
		if(CanPerformGroundTrace())
		{
			const FVector PendingDelta = GenerateIterationDelta().Delta;
			FMovementHitResult InitialGround = SweepingData.OriginalContacts.GroundContact;

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
				if(VerticalDeltaGroundTraceDistance > 0 || SweepingData.EdgeHandling == EMovementEdgeHandlingType::Follow)
					ApplyImpactOnDeltas(InitialGround);

				// If we are actually trying to leave an edge,
				// we don't apply the ground stickyness.
				// This might be added as a separate setting but the wanted behavior
				// is that you always "fly" out over edges  
				if(!IsLeavingEdge(InitialGround))
				{
					VerticalDeltaGroundTraceDistance += SweepingData.BonusGroundedTraceDistanceWhileGrounded;
					bStickToGround = SweepingData.BonusGroundedTraceDistanceWhileGrounded > 0;
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
			return;

		TryAlignWorldUpWithImpact(MovementHit);
		ApplyGroundEdgeInformation(MovementHit);
		ApplyImpactOnDeltas(MovementHit);
		ChangeGroundedState(MovementHit);
		IterationState.ApplyMovement(MovementHit.Time, MovementHit.Location);
	}

	protected void HandleIterationDeltaMovementWallImpact(FMovementHitResult& MovementHit)
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"HandleIterationDeltaMovementWallImpact");
#endif

		check(MovementHit.Type == EMovementImpactType::Wall);

		if(HandleMovementImpactInternal(MovementHit, EMovementResolverAnyShapeTraceImpactType::Iteration))
			return;

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
			FMovementResolverGroundTraceSettings Settings;
			Settings.NormalForImpactTypeGenerationType = EMovementResolverNormalForImpactTypeGenerationType::Normal;
			Settings.bRedirectTraceIfInvalidGround = true;
			Settings.CustomTraceTag = n"GroundTraceAtWall";
			GroundAtWallImpact = QueryGroundShapeTrace(MovementHit.Location,
				-CurrentWorldUp * GroundTraceAtWallDistance,
				Settings);

			if(GroundAtWallImpact.IsValidBlockingHit() && HandleMovementImpactInternal(GroundAtWallImpact, EMovementResolverAnyShapeTraceImpactType::GroundAtWall))
				return;

			ApplyGroundEdgeInformation(GroundAtWallImpact);

			// Update the grounded state before we perform the wall impact
			ChangeGroundedState(GroundAtWallImpact);
		}

		const bool bPerformedAlignment = TryAlignWorldUpWithImpact(MovementHit);

		// Normal movement
		if(!SweepingData.bHasSyncedLocationInfo || bPerformedAlignment)
		{
			ApplyImpactOnDeltas(MovementHit);
			IterationState.PhysicsState.WallContact = MovementHit;
			IterationState.ApplyMovement(MovementHit.Time, MovementHit.Location);
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
			return;

		const bool bPerformedAlignment = TryAlignWorldUpWithImpact(MovementHit);
		
		// Normal movement
		if(!SweepingData.bHasSyncedLocationInfo || bPerformedAlignment)
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
			FMovementResolverGroundTraceSettings Settings;

			// If we are set to follow edges, we always want to use the normal
			if(SweepingData.EdgeHandling == EMovementEdgeHandlingType::Follow)
				Settings.NormalForImpactTypeGenerationType = EMovementResolverNormalForImpactTypeGenerationType::Normal;
			else
				Settings.NormalForImpactTypeGenerationType = EMovementResolverNormalForImpactTypeGenerationType::ImpactNormal;

			Settings.bRedirectTraceIfInvalidGround = true;

			FMovementHitResult PendingGround = QueryGroundShapeTrace(IterationState.CurrentLocation,
				-CurrentWorldUp * CurrentGroundTraceDistance,
				Settings);

			if(PendingGround.IsValidBlockingHit() && HandleMovementImpactInternal(PendingGround, EMovementResolverAnyShapeTraceImpactType::Ground))
				return;

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
					}	
				}
			}
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
				GenerateIterationHit(SweepingData, IterationState, IterationHit);

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

		// On the remote side, we just move to the wanted location
		IterationState.DeltaToTrace = GenerateIterationDelta().Delta;
		FVector PendingLocation = IterationState.CurrentLocation + IterationState.DeltaToTrace;

		float CurrentGroundTraceDistance = GetGroundTraceDistance();

		// This is a grounded movement so we need to make sure that we find the ground.
		// So we add some extra trace distance in case the stepdown is not set correctly
		if(ShouldValidateRemoteSideGroundPosition())
			CurrentGroundTraceDistance += SweepingData.ShapeSizeForMovement;

		if(CurrentGroundTraceDistance > 0)
		{
			FMovementResolverGroundTraceSettings Settings;
			Settings.NormalForImpactTypeGenerationType = EMovementResolverNormalForImpactTypeGenerationType::ImpactNormal;
			Settings.bRedirectTraceIfInvalidGround = false;

			// We trace for the ground, using a sphere with the same amount as the capsule radius.
			// Since the networked replicated position might place us inside a shape,
			// We start the trace a bit higher up, but still inside the original shape,
			// making it possible to find the correct ground position.
			FHazeMovementTraceSettings TraceSettings = IterationTraceSettings;
			TraceSettings.OverrideTraceShape(FHazeTraceShape::MakeSphere(SweepingData.ShapeSizeForMovement));

			// Update the grounded impact with the remote trace
			IterationState.PhysicsState.GroundContact = QueryGroundShapeTrace(
				TraceSettings,
				PendingLocation, 
				-CurrentWorldUp * CurrentGroundTraceDistance, 
				CurrentWorldUp,
				Settings);

			// Use the impact for remote impact callbacks
			AccumulatedImpacts.AddImpact(IterationState.PhysicsState.GroundContact);
		}

		IterationState.ApplyMovement(1, PendingLocation);
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
		if(SweepingData.EdgeHandling == EMovementEdgeHandlingType::Follow)
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
		const float BonusTrace = SweepingData.ShapeSizeForMovement * 0.1;

		// Use Impact Location because IterationState has not yet applied the movement
		AlignedState.CurrentLocation = Impact.Location + (PotentialNewWorldUp * BonusTrace);

		FHazeMovementTraceSettings AlignedTraceSettings = IterationTraceSettings;
		ChangeCurrentWorldUp(AlignedState, AlignedTraceSettings, PotentialNewWorldUp);

		FMovementResolverGroundTraceSettings GroundTraceSettings;
		GroundTraceSettings.NormalForImpactTypeGenerationType = EMovementResolverNormalForImpactTypeGenerationType::ImpactNormal;
		GroundTraceSettings.bResolveStartPenetrating = false;
		GroundTraceSettings.CustomTraceTag = n"NewWorldUpGround";

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

		if(SweepingData.EdgeHandling == EMovementEdgeHandlingType::Follow)
			ApplyGroundEdgeInformation(AlignedGround);
		
		// Finalize the new grounded location
		AlignedState.CurrentLocation = AlignedGround.Location;

		IterationState = AlignedState;
		IterationTraceSettings = AlignedTraceSettings;

		// When sweeping and aligning with ground, we want to maintain our velocity when hitting the ground coming from airborne
		bScopedKeepVelocityInRedirections = true;
		ApplyImpactOnDeltas(AlignedGround);
		bScopedKeepVelocityInRedirections = false;
		ChangeGroundedState(AlignedGround);
		return true;
	}

	protected bool CanApplyGroundEdgeInformation(FMovementHitResult HitResult, bool bForceEvenIfSet = false) const
	{
		if(SweepingData.EdgeHandling == EMovementEdgeHandlingType::None)
			return false;

		if(HitResult.EdgeResult.Type != EMovementEdgeType::Unset && !bForceEvenIfSet)
			return false;

		if(!HitResult.IsAnyGroundContact())
			return false;

		return true;
	}

	/** Applies the edge information to the movement hit result */
	protected void ApplyGroundEdgeInformation(FMovementHitResult& HitResult, bool bForceEvenIfSet = false)
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"ApplyGroundEdgeInformation");
#endif

		if(!CanApplyGroundEdgeInformation(HitResult, bForceEvenIfSet))
			return;

		FVector MovementDirection = IterationState.GetHorizontalMovementDirection(CurrentWorldUp);
		if(MovementDirection.IsNearlyZero())
			 MovementDirection = IterationState.CurrentRotation.ForwardVector;

		const bool bFollowEdges = SweepingData.EdgeHandling == EMovementEdgeHandlingType::Follow;

		// If we are set to follow edges, and the angle between the impact normal and the normal is bigger than the walkable distance,
		// we call this and edge directly
		float AngleBetweenNormals = HitResult.Normal.GetAngleDegreesTo(HitResult.ImpactNormal);
		if(bFollowEdges && AngleBetweenNormals > SweepingData.WalkableSlopeAngle)
		{
			FMovementEdge& EdgeInfo = HitResult.EdgeResult;
			EdgeInfo.Type = EMovementEdgeType::Edge;
			EdgeInfo.Distance = 0;
			EdgeInfo.EdgeNormal = HitResult.Normal;
		}
		// Else we trace for an edge the normal way
		else
		{
			HitResult.EdgeResult = GetEdgeInformation(HitResult, MovementDirection, SweepingData.EdgeRedirectType);	
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
			HitResult.EdgeResult.UnstableDistance = SweepingData.MaxEdgeDistanceUntilUnstable;
		}

		if(SweepingData.bConsiderLandingOnUnstableEdgeAsUnwalkableGround)
		{
			if(!SweepingData.OriginalContacts.GroundContact.IsWalkableGroundContact() && HitResult.IsOnUnstableEdge())
			{
				// We cannot walk on an unstable edge if we are not currently grounded!
				HitResult.bIsWalkable = false;
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
			return SweepingData.bRedirectMovementOnWallImpacts;
		}
		else if(Impact.IsCeilingImpact())
		{
			return SweepingData.bRedirectMovementOnCeilingImpacts;
		}
		else if(Impact.IsAnyGroundContact())
		{
			return SweepingData.bRedirectMovementOnGroundImpacts;
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
	FMovementDelta ProjectMovementUponImpact(FMovementDelta DeltaState, FMovementHitResult Impact, FMovementHitResult GroundedState) const
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
			else if(Impact.IsOnUnstableEdge() && DeltaState.Delta.DotProduct(Impact.Normal) > 0)
			{
				return ProjectDeltaUponUnstableEdgeImpact(DeltaState, Impact, GroundedState);
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
		FVector DeltaRedirectNormal = Impact.Normal;

		// If we are on edges, we use the impact normal instead to not get sucked down
		if(IsLeavingEdge(Impact))
		{
			if(!Impact.EdgeResult.OverrideRedirectNormal.IsNearlyZero())
				DeltaRedirectNormal = Impact.EdgeResult.OverrideRedirectNormal;
			else
				DeltaRedirectNormal = Impact.ImpactNormal;
		}

		// We redirect the delta without any loss.
		FMovementDelta ConstrainedDeltaState = DeltaState.GetHorizontalPart(DeltaRedirectNormal);
		ConstrainedDeltaState = ConstrainedDeltaState.SurfaceProject(DeltaRedirectNormal, CurrentWorldUp);
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

		// adding ground friction will remove the vertical part of the movement since we moved into the ground
		ConstrainedDeltaState = ConstrainedDeltaState.GetHorizontalPart(Impact.Normal);
		return ConstrainedDeltaState.SurfaceProject(Impact.Normal, CurrentWorldUp);
	}

	/**
	 * We are leaving an unstable edge
	 */
	FMovementDelta ProjectDeltaUponUnstableEdgeImpact(FMovementDelta DeltaState, FMovementHitResult Impact, FMovementHitResult GroundedState) const
	{
		// Just let the delta be as it is
		return DeltaState;
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
		if(!SweepingData.bCanPerformGroundTrace)
			return false;

		if(IsLeavingGround())
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
		return VerticalDeltaGroundTraceDistance + SweepingData.SafetyDistance.Y + 0.125;
	}

	// Sweeping data only uses the normal to determine what kind of impact this is
	FVector GetNormalForImpactTypeGeneration(FHitResult HitResult) const override
	{
		return HitResult.Normal;
	}

	bool ShouldAlignWorldUpWithGround() const override
	{
		return SweepingData.AlignWithImpactSettings.bAlignWithGround;
	}

	bool ShouldAlignWorldUpWithWall() const override
	{
		return SweepingData.AlignWithImpactSettings.bAlignWithWall;
	}

	bool ShouldAlignWorldUpWithCeiling() const override
	{
		return SweepingData.AlignWithImpactSettings.bAlignWithCeiling;
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
}