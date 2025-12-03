/** 
 * A simple resolver that never does any iterations
 * This one only places the actor where it wants to be
*/
class UTeleportingMovementResolver : UBaseMovementResolver
{
	default RequiredDataType = UTeleportingMovementData;

	private const UTeleportingMovementData TeleportingData;

	void PrepareResolver(const UBaseMovementData Movement) override
	{
		TeleportingData = Cast<UTeleportingMovementData>(Movement);
		
		Super::PrepareResolver(Movement);

#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"PrepareResolver");
#endif

		IterationState.PhysicsState = FMovementContacts();
		IterationState.DeltaToTrace = GenerateIterationDelta().Delta;
		IterationState.CurrentLocation = Movement.OriginalActorTransform.Location;
		IterationState.CurrentRotation = Movement.OriginalActorTransform.Rotation;
	}

	FMovementDelta GenerateIterationDelta() const override
	{
		return TeleportingData.DeltaStates.GetDelta();
	}

#if EDITOR
	void ResolveRerun() override
	{
		check(TeleportingData != nullptr);

		Resolve();
		PostResolve();

		// Did the rerun succeed
		check(TeleportingData.DebugFinalTransform.Equals(IterationState.GetCurrentTransform()));
	}
#endif

	void ResolveAndApplyMovementRequest(UHazeMovementComponent MovementComponent) override
	{
#if !RELEASE
	 	check(TeleportingData != nullptr);
#endif

		// In the editor, we add the rerun each movement frame
#if EDITOR
		UTeleportingMovementData RerunData = Cast<UTeleportingMovementData>(MovementComponent.AddRerunData(TeleportingData, this));
#endif

		// Temporal log the first iteration state
#if !RELEASE
		MovementDebug::AddInitialDebugInfo(
			MovementComponent,
			TeleportingData,
			this
		);
#endif
		
		// This will resolve the transient state
		// and save the result in the "FinalResult" param
		Resolve();
		PostResolve();

		// Add all the data collected in the teleport
		ApplyResolve(MovementComponent);

#if EDITOR	
		// Update the final transform for rerun data so we can validate that
		if(RerunData != nullptr)
			RerunData.DebugFinalTransform = IterationState.GetCurrentTransform();
#endif

		// Temporal log the final state
#if !RELEASE
		MovementDebug::AddMovementResolvedState(
			MovementComponent,
			TeleportingData,
			this,
			IterationState,
			TeleportingData.IterationTime
		);
#endif
	}

	protected void Resolve() override
	{
		RunPrepareNextIteration();

		if(TeleportingData.FinalGroundContactType == ETeleportingMovementFinalGroundType::KeepCurrent)
		{
			IterationState.PhysicsState.GroundContact = TeleportingData.OriginalContacts.GroundContact;
		}
		// We have a custom ground contact that should be used as final
		else if(TeleportingData.FinalGroundContactType == ETeleportingMovementFinalGroundType::ManuallyOverride)
		{
			const EMovementOverrideFinalGroundType OverrideType = TeleportingData.OverrideFinalGroundContactType;
			
			// The override wants to find an actual valid grounded location
			if(OverrideType == EMovementOverrideFinalGroundType::ActiveWithValidation
				&& TeleportingData.OverrideFinalGroundContact.IsValidBlockingHit())
			{	
				FMovementResolverGroundTraceSettings TraceSettings;
				TraceSettings.bRedirectTraceIfInvalidGround = false;
				TraceSettings.CustomTraceTag = n"ValidateOverrideGround";
				
				IterationState.PhysicsState.GroundContact = QueryGroundShapeTrace(
					TeleportingData.OverrideFinalGroundContact.Location + (CurrentWorldUp * TeleportingData.SafetyDistance.Y), 
					-CurrentWorldUp * TeleportingData.ShapeSizeForMovement * 2,
					TraceSettings,
					);
			}
			else if(OverrideType == EMovementOverrideFinalGroundType::Active)
			{
				IterationState.PhysicsState.GroundContact = GenerateDefaultGroundedState(TeleportingData.OverrideFinalGroundContact, CurrentWorldUp, FHazeTraceTag(n"OverrideGround_Active"));
			}
		}

		IterationState.CurrentLocation = GetUnhinderedPendingLocation();

		FQuat FinalRotation = FinalizeRotation(TeleportingData.TargetRotation, CurrentWorldUp);
		IterationState.CurrentRotation = FinalRotation;

		if(TeleportingData.FinalGroundContactType == ETeleportingMovementFinalGroundType::Trace)
		{
			FMovementResolverGroundTraceSettings TraceSettings;
			TraceSettings.bRedirectTraceIfInvalidGround = false;
			TraceSettings.CustomTraceTag = n"ValidateOverrideGround";
			
			IterationState.PhysicsState.GroundContact = QueryGroundShapeTrace(
				IterationState.CurrentLocation + (CurrentWorldUp * TeleportingData.SafetyDistance.Y), 
				-CurrentWorldUp * 20,
				TraceSettings,
				);
		}
	}

	UFUNCTION(BlueprintOverride, Meta = (BlueprintThreadSafe))
	protected void ResolveParallel()
	{
		Resolve();
	}

	bool PrepareNextIteration() override
	{
		if(!Super::PrepareNextIteration())
			return false;

#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"PrepareNextIteration");
#endif

		IterationState.DeltaToTrace = GenerateIterationDelta().Delta;

		return true;
	}

	void StopResolving() override
	{
		Super::StopResolving();
		
		IterationState.PerformedMovementAlpha = 1.0;
	}

	UFUNCTION(BlueprintOverride)
	void ApplyResolve(UHazeMovementComponentBase MovementComponent)
	{
		MovementComponent.SetMovingStatus(true, TeleportingData.StatusInstigator);
		auto MoveComp = Cast<UHazeMovementComponent>(MovementComponent);
		ApplyResolvedData(MoveComp);
		PostApplyResolvedData(MoveComp);
		MovementComponent.SetMovingStatus(false, TeleportingData.StatusInstigator);
	}

	protected void ApplyResolvedData(UHazeMovementComponent MovementComponent) override
	{
		Super::ApplyResolvedData(MovementComponent);

		MovementComponent.SetContactsAndImpactsInternal(IterationState.PhysicsState, CurrentWorldUp, AccumulatedImpacts);

		// Change the velocity
		FVector FinalVelocity = TeleportingData.DeltaStates.GetDelta().Velocity;
		FVector HorizontalVelocity = FinalVelocity.VectorPlaneProject(CurrentWorldUp);
		MovementComponent.SetVelocityInternal(HorizontalVelocity, FinalVelocity - HorizontalVelocity);

		// The sweeping data has no falling information so we stop doing that if we use this resolver
		if (IterationState.PhysicsState.GroundContact.IsAnyGroundContact() && MovementComponent.IsFalling())
		{
			MovementComponent.StopFalling(IterationState.CurrentLocation, MovementComponent.PreviousVelocity);
		}

		// Override the target facing rotation so if nothing new sets it, we have the current rotation
		MovementComponent.SetPendingTargetFacingRotationInternal(IterationState.CurrentRotation);

		// Finally, apply the actor location and rotation
		MovementComponent.HazeOwner.SetActorLocationAndRotation(IterationState.CurrentLocation, IterationState.CurrentRotation);
	}
	
	EMovementResolverHandleMovementImpactResult HandleMovementImpact(FMovementHitResult Hit, EMovementResolverAnyShapeTraceImpactType ImpactType) override final
	{
		check(false, "This function is not implemented on TeleportingMovement since it doesn't use iterations!");
		return EMovementResolverHandleMovementImpactResult::Continue;
	}
}