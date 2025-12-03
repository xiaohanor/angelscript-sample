/**
 * A MovementResolver will initialize using a MovementData, and then perform (i.e Resolve) how we should move based on that initial state.
 * 
 * We start by preparing it with PrepareResolver().
 * This function reads data from the movement data, and resets all settings to an initial state.
 * Movement Resolvers are not automatically reset or recreated, so it is important that ALL data used is reset.
 * If you add any new properties to your resolver, make sure you reset it here!
 * 
 * Then Resolve() will be called, which is the main function of the resolver. Here is where all of the movement code goes.
 * 
 * Once Resolve() is finished, ApplyResolve() is called, where we get a mutable reference to a UHazeMovementComponent.
 * This is the only place on the resolver where we are allowed to modify anything outside of the resolver.
 * 
 * The resolver can be Rerun, this means that PrepareResolver() and Resolve() are called, but we never call ApplyResolve()
 * We do this so that we can go back in time in the temporal logger, rerun a move and debug or analyze the results and paths it took.
 * This is the main reason why it is important that the resolver only modifies itself and nothing else while resolving.
 * 
 * There is also experimental support for parallel resolving, where the resolver can run on multiple threads/cores.
 */
UCLASS(Abstract, NotBlueprintable)
class UBaseMovementResolver : UHazeMovementResolver
{
	access Protected = protected, UBaseMovementData (inherited), UMovementResolverExtension (inherited), UHazeMovementComponent, UMovementTemporalRerunExtender;
	access ProtectedEditDefaults = private, *(editdefaults);
	access PrepareProtected = protected, UBaseMovementData (inherited), UMovementResolverExtension (inherited), UMovementTemporalRerunExtender;
	access MoveCompProtected = protected, UHazeMovementComponent;
	access MoveCompPrivate = private, UHazeMovementComponent;
	access MoveDebugProtected = protected, UMovementTemporalRerunExtender;
	access Extensions = private, UHazeMovementComponent, UMovementResolverExtension (inherited), MovementDebug, UMovementResolverTemporalLog, UMovementTemporalRerunExtender;
	access ResolverTemporalLog = protected, UMovementResolverTemporalLog (inherited), FMovementResolverTemporalLogContextScope, UMovementResolverExtension (inherited);

	access:MoveCompProtected
	const TSubclassOf<UBaseMovementData> RequiredDataType;

	private const UBaseMovementData InternalData;

	access:MoveCompProtected
	const TSubclassOf<UMovementResolverMutableData> MutableDataClass = UMovementResolverMutableData;

	access:Protected
	UMovementResolverMutableData MutableData;

	access:MoveCompPrivate
	const UHazeMovementComponent InternalMovementComponent;

	FMovementResolverState IterationState;
	int IterationCount = 0;
	FHazeMovementTraceSettings IterationTraceSettings;

	FMovementAccumulatedImpacts AccumulatedImpacts;

	// Extensions
	access:Extensions
	TArray<UMovementResolverExtension> Extensions;

#if !RELEASE
	access:ResolverTemporalLog
	UMovementResolverTemporalLog ResolverTemporalLog;
	access:ResolverTemporalLog
	FString TemporalLogPageName = "Resolver";
	access:MoveCompProtected
	uint DebugPreparedFrame = 0;
#endif

	const AHazeActor GetOwner() const property
	{
		return InternalMovementComponent.HazeOwner;
	}

	bool HasMovementControl() const
	{
		return InternalMovementComponent.HasMovementControl();
	}

	access:Protected
	FQuat FinalizeRotation(FQuat Rotation, FVector UpVector) const
	{
		return InternalMovementComponent.FinalizeRotation(Rotation, UpVector);
	}

	access:Protected
	bool IsApplyingInParallel() const
	{
		return InternalMovementComponent.IsApplyingInParallel();
	}

	/** Called right before the resolver is used */
	access:Protected
	void PrepareResolver(const UBaseMovementData Movement)
	{
#if !RELEASE
		if(ResolverTemporalLog == nullptr)
			ResolverTemporalLog = NewObject(this, UMovementResolverTemporalLog, NAME_None, true);

		ResolverTemporalLog.PrepareResolve(InternalMovementComponent, this);

		devCheck(Movement.IsA(RequiredDataType), "Resolver " + this + " can't handle " + Movement + ". Its the wrong type");
		if(!InternalMovementComponent.IsPerformingDebugRerun())
		{
			DebugPreparedFrame = Time::FrameNumber;
			devCheck(Movement.DebugPreparedFrame == DebugPreparedFrame, f"Movement {Movement.GetName()} was not prepared the same frame as it was applied");	
		}

		devCheck(MutableData != nullptr, "MutableData has not been created!");
#endif
	
		InternalData = Movement;

		// Assume that the max amount of impacts will be two per iteration, since we can get both a hit and ground hit in the same iteration.
		AccumulatedImpacts.Reset(InternalData.MaxRedirectIterations * 2);

		// IterationState should always be reset by the child resolver
		IterationCount = 0;
		MutableData.OnPrepareResolver();

		IterationTraceSettings = InternalData.TraceSettings;	
		IterationTraceSettings.PreparePhysicsQueries(InternalData.OriginalActorTransform.Rotation);
	 	IterationTraceSettings.AddPermanentIgnoredPrimitives(InternalData.IgnoredComponents);	
	 	IterationTraceSettings.AddPermanentIgnoredActors(InternalData.IgnoredActorsThisFrame);
	}

	access:Protected
	void PostPrepareResolver(const UBaseMovementData Movement)
	{
#if EDITOR
		// We don't run PrepareExtension() when rerunning, since that function gets state from the world.
		if(Movement.bIsEditorRerunData)
			return;
#endif

		for(UMovementResolverExtension Extension : Extensions)
		{
			check(IsValid(Extension));
			check(IsValid(Movement));
			Extension.PrepareExtension(this, Movement);
		}
	}

	access:MoveCompPrivate
	void Resolve()
	{
		devError(f"Movement resolver {this} has not implement 'Resolve'. for movement {InternalData}");
	}

	access:MoveCompPrivate
	UFUNCTION(BlueprintOverride, Meta = (BlueprintThreadSafe, NoSuperCall))
	void ResolveParallel()
	{
		devError(f"Movement resolver {this} has not implement 'ResolveParallel'. for movement {InternalData}");
	}

	access:MoveCompPrivate
	UFUNCTION(BlueprintOverride, Meta = (NoSuperCall))
	void ApplyResolve(UHazeMovementComponentBase MovementComponent)
	{
		devError(f"Movement resolver {this} has not implement 'ApplyResolve'. for movement {InternalData}");
	}

#if EDITOR
	access:MoveDebugProtected
	void ResolveRerun()
	{
		devError(f"Movement resolver {this} has not implement 'RerunResolve'. for movement {InternalData}");
	}
#endif
	
	access:MoveCompProtected
	void ResolveAndApplyMovementRequest(UHazeMovementComponent MovementComponent)
	{
		devError(f"Movement resolver {this} has not implement 'Resolve'. for movement {InternalData}");
	}

	bool RunPrepareNextIteration()
	{
		if(!PrepareNextIteration())
			return false;

		PostPrepareNextIteration();

		// This is silly, but since the conditions are run before PostPrepareNextIteration(), but PostPrepareNextIteration()
		// can modify the delta to trace, we must run the condition here again.
		// FB TODO: Fix this (and many other things) next project when resolver extensions will be better implemented.
		if(IterationState.DeltaToTrace.SizeSquared() <= Math::Square(IterationTraceSettings.TraceLengthClamps.Min))
		{
			IterationState.DeltaToTrace = FVector::ZeroVector;
			return false;
		}

		return true;
	}

	protected bool PrepareNextIteration()
	{
#if !RELEASE
		ResolverTemporalLog.PrepareIteration();
		FMovementResolverTemporalLogContextScope Scope(this, n"PrepareNextIteration");
#endif

		const bool bFirstIteration = IterationCount == 1;
		for(UMovementResolverExtension Extension : Extensions)
		{
#if !RELEASE
			FMovementResolverTemporalLogContextScope ExtensionScope(this, Extension.Class.Name);
#endif
			if(!Extension.OnPrepareNextIteration(bFirstIteration))
				return false;
		}
		
		MutableData.OnPrepareNextIteration();

		return true;
	}

	protected void PostPrepareNextIteration()
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"PostPrepareNextIteration");
#endif

		const bool bFirstIteration = IterationCount == 1;
		for(UMovementResolverExtension Extension : Extensions)
		{
#if !RELEASE
			FMovementResolverTemporalLogContextScope ExtensionScope(this, Extension.Class.Name);
#endif
			Extension.PostPrepareNextIteration(bFirstIteration);
		}
	}

	FMovementDelta GenerateIterationDelta() const
	{
		FMovementDelta FinalDelta = IterationState.GetDelta();
		return FinalDelta * IterationState.RemainingMovementAlpha;
	}

	FVector GetUnhinderedPendingLocation() const
	{
		FVector PendingLocation = IterationState.CurrentLocation + IterationState.DeltaToTrace;

		for(UMovementResolverExtension Extension : Extensions)
		{
#if !RELEASE
			FMovementResolverTemporalLogContextScope ExtensionScope(this, Extension.Class.Name);
#endif
			Extension.OnUnhinderedPendingLocation(PendingLocation);
		}

		return PendingLocation;
	}

	bool ShouldApplySplineLock() const
	{
		return InternalData.GetShouldApplySplineLockConstraint() && HasMovementControl();
	}

	/**
	 * Format a trace tag like so: Context_TraceTag_SubTag
	 * @param TraceTag What is the name of the current trace?
	 * @param Context What context (function) is the trace performed in?
	 * @param SubTag Any additional tag that might be useful.
	 */
	FHazeTraceTag GenerateTraceTag(
		FName TraceTag,
		FName Context = NAME_None,
		FName SubTag = NAME_None) const
	{	
		FName FinalName = TraceTag != NAME_None ? TraceTag : n"Movement";

#if !RELEASE
		if(Context != NAME_None && SubTag != NAME_None)
		{
			FinalName = FName(f"{Context}_{FinalName}_{SubTag}");
		}
		else if(Context != NAME_None)
		{
			FinalName = FName(f"{Context}_{FinalName}");
		}
		else if(SubTag != NAME_None)
		{
			FinalName = FName(f"{FinalName}_{SubTag}");
		}

		check(!FinalName.ToString().Contains("/"), "Can't have / in TraceTags! This will break the poor temporal logger ;_; ");
#endif

		return FHazeTraceTag(FinalName);
	}

	const FVector& GetCurrentWorldUp() const property
	{
		return InternalData.WorldUp;
	}

	const FVector GetGravityDirection() const
	{
		return InternalMovementComponent.GravityDirection;
	}

	float GetIterationTime() const property
	{
		return InternalData.IterationTime;
	}

	int GetMaxRedirectIterations() const property
	{
		return InternalData.MaxRedirectIterations;
	}

	int GetIterationDepenetrationCount() const property
	{
		return MutableData.IterationDepenetrationCount;
	}

	void SetIterationDepenetrationCount(int Value) property
	{
		MutableData.IterationDepenetrationCount = Value;
	}

	const FHazeTraceShape& GetTraceShape() const property
	{
		return IterationTraceSettings.GetTraceShape();
	}

	FVector GetPenetrationAdjustment(FHitResult IterationHit) const
	{
		check(!IterationHit.Normal.IsZero(), "Trying to call GetPenetrationAdjustment() with an IterationHit that has a ZeroVector Normal, this will return no adjustment at all!");
		
		const float PenetrationPullbackDistance = 0.125;
		const float PenetrationDepth = (IterationHit.PenetrationDepth > 0.0 ? IterationHit.PenetrationDepth : PenetrationPullbackDistance);
		return IterationHit.Normal * (PenetrationDepth + PenetrationPullbackDistance);
	}

	// Generate the default iteration hit for the iteration
	protected void GenerateIterationHit(const UBaseMovementData Movement, FMovementResolverState& State, FMovementHitResult& IterationHit, FName CustomTraceTag = NAME_None)
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"GenerateIterationHit");
#endif

		while(true)
		{
			if(!Movement.bHasSyncedLocationInfo)
			{
				// Generate the movement hit result
				// from the current directed movement delta
				FHazeTraceTag TraceTag;
				if(IterationDepenetrationCount == 0)
				{
					TraceTag = GenerateTraceTag(CustomTraceTag);
				}
				else
				{
					TraceTag = GenerateTraceTag(CustomTraceTag, NAME_None, FName(f"Depenetration_{IterationDepenetrationCount}"));
				}

				IterationHit = QueryShapeTrace(
					State.CurrentLocation, 
					State.DeltaToTrace, 
					TraceTag);

				// This is a valid trace
				if(!IterationHit.bStartPenetrating)
					break;

				if(IterationDepenetrationCount >= Movement.MaxDepenetrationIterations)
					break;

				if(PreResolveStartPenetrating(IterationHit))
					continue;

				State.CurrentLocation = ResolveStartPenetrating(IterationHit);
				IterationDepenetrationCount += 1;
			}
			// Replicated move
			else
			{
				// Generate the movement hit result
				// from the current directed movement delta
				// but add the safety distance
				// since the replicated move might be at a collision
				// but since the safety distance is pulling us back away from the impact
				// we need to add that to actually be able to replicate the impact
				FVector BonusAmount = State.GetDelta().Velocity.GetSafeNormal();
				BonusAmount *= Math::Lerp(Movement.SafetyDistance.X, Movement.SafetyDistance.Y, BonusAmount.DotProductLinear(State.WorldUp)) * 2; 

				const FHazeTraceTag TraceTag = GenerateTraceTag(CustomTraceTag, SubTag = n"Remote");
				IterationHit = QueryShapeTrace(
					State.CurrentLocation, 
					State.DeltaToTrace + BonusAmount, 
					TraceTag);
					
				// The remote side never resolves depenetration
				// Instead, we just follow the control side
				// if we are inside any geometry
				if(IterationHit.bStartPenetrating)
					IterationHit = FMovementHitResult();

				break;
			}
		}
	}

	/**
	 * Default shape trace function.
	 * Will trace along the 'DeltaToTrace' and stop at the first blocking impact
	 * Will also fix potential bad normals
	 */
	FMovementHitResult QueryShapeTrace(
		FVector TraceFromLocation,
		FVector DeltaToTrace, 
		FHazeTraceTag TraceTag) const
	{
		const FVector WorldUp = CurrentWorldUp;
		return QueryShapeTrace(IterationTraceSettings, 
			TraceFromLocation, 
			DeltaToTrace, 
			WorldUp,
			TraceTag);	
	}

	/**
	 * Default shape trace function.
	 * Will trace along the 'DeltaToTrace' and stop at the first blocking impact
	 * Will also fix potential bad normals
	 */
	FMovementHitResult QueryShapeTrace(
		FHazeMovementTraceSettings TraceSettings,
		FVector TraceFromLocation,
		FVector DeltaToTrace, 
		FVector WorldUp,
		FHazeTraceTag TraceTag) const
	{
	
		// We need to trace with a extra safety margin distance. This so we make sure we don't end up
		// touching the collision because that will make the next trace be defined as 'start penetrating'.
		FVector ExtraDeltaTrace = FVector::ZeroVector;
		float SafetyMargin = 0;
		GetSafetyForTraceDelta(DeltaToTrace, ExtraDeltaTrace, SafetyMargin);

		// Perform the trace
		FHitResult HitResult = TraceSettings.QueryShapeTrace(
				TraceFromLocation, 
				DeltaToTrace + ExtraDeltaTrace,
				TraceTag);

		FixupTraceImpactNormal(HitResult);
		// // Hitting edges on bsp's can give us some really funky impact result
		// // So if the impact normal and the normal are point 90 deg away from each other
		// // we just use the normal
		// if(Math::Abs(HitResult.ImpactNormal.DotProduct(HitResult.Normal)) < KINDA_SMALL_NUMBER)
		// {
		// 	HitResult.ImpactNormal = HitResult.Normal;
		// }

		const FMovementHitResult FinalizedHit = GenerateDefaultMovementHitResult(HitResult, WorldUp, SafetyMargin, TraceTag);

#if !RELEASE
		ResolverTemporalLog.MovementHit(FinalizedHit, TraceSettings.TraceShape, TraceSettings.CollisionShapeOffset);
#endif

		return FinalizedHit;
	}

	/**
	 * Default shape trace function.
	 * Will trace along the 'DeltaToTrace' and stop at the first blocking impact
	 */
	FMovementHitResult QueryLineTrace(
		FHazeMovementTraceSettings TraceSettings,
		FVector TraceFromLocation,
		FVector DeltaToTrace, 
		FVector WorldUp,
		FHazeTraceTag TraceTag) const
	{
		// Perform the trace
		const FHitResult HitResult = TraceSettings.QueryLineTrace(
			TraceFromLocation, 
			DeltaToTrace,
			TraceTag, 
		);

		// Line trace has no safety margin
		const FMovementHitResult FinalizedHit = GenerateDefaultMovementHitResult(HitResult, WorldUp, 0, TraceTag); 

#if !RELEASE
		ResolverTemporalLog.MovementHit(FinalizedHit, FHazeTraceShape::MakeLine(), FVector::ZeroVector);
#endif

		return FinalizedHit;
	}	

	/**
	 * Default shape trace function.
	 * Will trace along the 'DeltaToTrace' and stop at the first blocking impact
	 */
	FMovementHitResult QueryLineTrace(
		FVector TraceFromLocation,
		FVector DeltaToTrace, 
		FHazeTraceTag TraceTag) const
	{
		return QueryLineTrace(IterationTraceSettings, 
			TraceFromLocation,
			DeltaToTrace,
			CurrentWorldUp, 
			TraceTag);
	}

    FOverlapResultArray QueryOverlaps(
        FVector OverlapLocation,
        FHazeTraceTag TraceTag) const
	{
		return QueryOverlaps(IterationTraceSettings, OverlapLocation, TraceTag);
	}

	FOverlapResultArray QueryOverlaps(
        FHazeMovementTraceSettings TraceSettings,
        FVector OverlapLocation,
        FHazeTraceTag TraceTag) const
	{
		FOverlapResultArray Overlaps = TraceSettings.QueryOverlaps(OverlapLocation, TraceTag);

#if !RELEASE
		ResolverTemporalLog.OverlapResults(
			TraceTag,
			Overlaps
		);
#endif

		return Overlaps;
	}

	// protected FMovementHitResult QueryLineUnderneathTrace(
	// 	FVector TraceFromLocation,
	// 	float TraceLength, 
	// 	FHazeTraceTag TraceTag,
	// 	FVector WorldUp = FVector::ZeroVector) const
	// {
	// 	const FVector WorldUpToUse = WorldUp.IsUnit() ? WorldUp : CurrentWorldUp;
	// 	FVector StartLocation = TraceFromLocation;
	// 	StartLocation += InternalData.TraceSettings.CollisionShapeOffset;
	// 	StartLocation -= WorldUpToUse * (InternalData.TraceSettings.TraceShape.GetExtent().DotProduct(WorldUpToUse) + InternalData.SafetyDistance.Y);
		
	// 	FVector TraceDelta = -WorldUpToUse * (TraceLength + InternalData.SafetyDistance.Y);
	// 	return QueryLineTrace(StartLocation, TraceDelta, TraceTag);
	// }

	/**
	 *
	 */
	FMovementHitResult QueryGroundShapeTrace(
		FVector StartLocation,
		FVector GroundTraceDelta,
		FMovementResolverGroundTraceSettings GroundTraceSettings = FMovementResolverGroundTraceSettings()) const
	{
		return QueryGroundShapeTrace(IterationTraceSettings, 
			StartLocation,
			GroundTraceDelta, 
			CurrentWorldUp,
			GroundTraceSettings);
	}

	/**
	 *
	 */
	FMovementHitResult QueryGroundShapeTrace(
		FVector StartLocation,
		FVector GroundTraceDelta,
		FVector WorldUp,
		FMovementResolverGroundTraceSettings GroundTraceSettings = FMovementResolverGroundTraceSettings()) const
	{
		return QueryGroundShapeTrace(IterationTraceSettings, 
			StartLocation,
			GroundTraceDelta, 
			WorldUp,
			GroundTraceSettings);
	}

	/**
	 *
	 */
	FMovementHitResult QueryGroundShapeTrace(
		FHazeMovementTraceSettings TraceSettings,
		FVector StartLocation,
		FVector GroundTraceDelta,
		FVector WorldUp,
		FMovementResolverGroundTraceSettings GroundTraceSettings = FMovementResolverGroundTraceSettings()) const
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"QueryGroundShapeTrace");
#endif

		if(GroundTraceDelta.IsNearlyZero())
			return FMovementHitResult(EMovementImpactType::NoImpact);

		const FHazeTraceShape GroundTraceShape = TraceSettings.GetTraceShape();
		if(!ensure(!GroundTraceShape.IsLine(), "Ground traces can't be lines, since they require valid normals."))
			return FMovementHitResult(EMovementImpactType::NoImpact);
		
		float StepdownAmountToPerform = GroundTraceDelta.Size();

#if !RELEASE
		ResolverTemporalLog.Value("StepdownAmountToPerform", StepdownAmountToPerform);
#endif

		FVector CurrentLocation = StartLocation;

		FVector TraceDir = GroundTraceDelta.GetSafeNormal();

		// The remote side might end up inside a shape, so we allow
		// some extra start height on the remote side.
		if(!HasMovementControl())
		{
			const float BonusDistance = InternalData.ShapeSizeForMovement;
			CurrentLocation -= TraceDir * BonusDistance;
			StepdownAmountToPerform += BonusDistance;
		}

		FHazeTraceTag TraceTag;
		FHitResult GroundHit;
		FMovementHitResult FinalizedGroundHit;

		const int MaxStepDownSubIterations = 2;
		for(int StepDownSubIteration = 0; StepDownSubIteration < MaxStepDownSubIterations; StepDownSubIteration++)
		{	
			// We need to trace with a extra safety margin distance. This so we make sure we don't end up
			// touching the collision because that will make the next trace be defined as 'start penetrating'.
			const float SafetyMargin = InternalData.SafetyDistance.Y;
			
			FName SubTag = NAME_None;
			if(GroundTraceSettings.bRedirectTraceIfInvalidGround || GroundTraceSettings.bResolveStartPenetrating)
				SubTag = FName(f"{StepDownSubIteration + 1}_of_{MaxStepDownSubIterations}");

			TraceTag = GenerateTraceTag(GroundTraceSettings.CustomTraceTag != NAME_None ? GroundTraceSettings.CustomTraceTag : n"GroundTrace", SubTag = SubTag);
			
			float FlatBottomRadius = 0;
			const EMovementShapeType ShapeType = GetMovementShapeType();
			if(GroundTraceSettings.bFlatCapsuleBottom && (ShapeType == EMovementShapeType::AlignedCapsule || ShapeType == EMovementShapeType::FlippedCapsule || ShapeType == EMovementShapeType::Sphere))
			{
				// To pretend that the bottom of the capsule is flat, we must sweep extra distance
				// This is later removed in ApplyPullback
				FlatBottomRadius = InternalData.ShapeSizeForMovement;

#if !RELEASE
				const FVector EndLocation = CurrentLocation + (TraceDir * (StepdownAmountToPerform + SafetyMargin));
				ResolverTemporalLog.Circle(f"Flat Bottom End {SubTag}", IterationState.ConvertLocationToShapeBottomLocation(EndLocation, TraceSettings), TraceDir, InternalData.ShapeSizeForMovement);
#endif
			}

			GroundHit = TraceSettings.QueryShapeTrace(
				CurrentLocation, 
				TraceDir * (StepdownAmountToPerform + SafetyMargin + FlatBottomRadius),
				TraceTag
			);

			FinalizedGroundHit = FMovementHitResult(GroundHit, SafetyMargin, FlatBottomRadius);
			
#if !RELEASE
			FinalizedGroundHit.TraceTag = TraceTag;
			ResolverTemporalLog.MovementHit(FinalizedGroundHit, TraceSettings.TraceShape, TraceSettings.CollisionShapeOffset);
#endif

			/** If we don't want to handle start penetrating, we return the impact as is */
			if(GroundHit.bStartPenetrating)
			{
				if(!GroundTraceSettings.bResolveStartPenetrating)
				{
					return FinalizedGroundHit;
				}
				else if(IterationDepenetrationCount >= InternalData.MaxDepenetrationIterations)
				{
					return FinalizedGroundHit;
				}
				// The control side can perform depenetration in grounded traces
				else if(HasMovementControl())
				{
					CurrentLocation = ResolveStartPenetrating(FinalizedGroundHit);
					MutableData.IterationDepenetrationCount++;
					continue;
				}
			}

			// Early Validation of actually being a impact since we need to do a pullback
			{
				FMovementHitResult ValidateHit = FinalizedGroundHit;
				ValidateHit.ApplyPullback();

				// The remote side uses the last ground impact
				// if we encounter a invalid ground trace.
				// This can happen, at wall edges
				if(!HasMovementControl() && ValidateHit.IsNotValid())
				{
					ValidateHit = InternalData.PreviousContacts.GroundContact;
				}

				// This is no actual impact
				if(!ValidateHit.IsValidBlockingHit())
				{
#if !RELEASE
					ResolverTemporalLog.OverwriteMovementHit(ValidateHit);
#endif
					return FMovementHitResult(EMovementImpactType::NoImpact);
				}
			}

			FixupTraceImpactNormal(GroundHit);

			// Setup the normal to use
			FVector CustomImpactNormal = FVector::ZeroVector;
			if(GroundTraceSettings.NormalForImpactTypeGenerationType == EMovementResolverNormalForImpactTypeGenerationType::Normal)
				CustomImpactNormal = GroundHit.Normal;
			else if(GroundTraceSettings.NormalForImpactTypeGenerationType == EMovementResolverNormalForImpactTypeGenerationType::ImpactNormal)
				CustomImpactNormal = GroundHit.ImpactNormal;

			FinalizedGroundHit = GenerateDefaultGroundedState(GroundHit, WorldUp, TraceTag, CustomImpactNormal, FlatBottomRadius);

#if !RELEASE
			ResolverTemporalLog.OverwriteMovementHit(FinalizedGroundHit);
#endif
	
			if(FinalizedGroundHit.IsAnyGroundContact())
			{
				// Are we still a ground after the validation
				return FinalizedGroundHit;
			}

			/**
			 * This is disabled for now, but I feel like it makes sense, so keeping it here for future reference
			 */
			// else if(ShouldAlignWorldUpWithContact(FinalizedGroundHit))
			// {
			// 	// We didn't find ground, but the contact we found was something we should align with, so we still count it as a valid hit!
			// 	FinalizedGroundHit.Type = EMovementImpactType::Ground;
			// 	return FinalizedGroundHit;
			// }
			
			// We have hit an invalid ground, so we need to trace more
			if(GroundTraceSettings.bRedirectTraceIfInvalidGround
				&& FinalizedGroundHit.Type != EMovementImpactType::Ground 
				&& InternalData.WalkableSlopeAngle > 0
				&& GroundHit.bBlockingHit)
			{				
				// Make sure we don't start inside the collision
				FMovementHitResult RedirectedGroundHit = FinalizedGroundHit;
				RedirectedGroundHit.ApplyPullback();

				CurrentLocation = RedirectedGroundHit.Location;

				TraceDir = (-CurrentWorldUp).VectorPlaneProject(GroundHit.Normal).GetSafeNormal();
				if(TraceDir.IsNearlyZero())
					break;

				const float Dot = TraceDir.DotProduct(RedirectedGroundHit.TraceDirection);
				if(Dot < KINDA_SMALL_NUMBER)
					break;

				const float OriginalStepDownAmountToPerform = StepdownAmountToPerform;

				// Lengthen the stepdown amount if we tilt the new trace so that we always hit the same plane as
				// we wanted to before.
				StepdownAmountToPerform /= Dot;
				
				StepdownAmountToPerform -= RedirectedGroundHit.Distance;

				StepdownAmountToPerform = Math::Min(StepdownAmountToPerform, OriginalStepDownAmountToPerform * 2);

				if(StepdownAmountToPerform <= 0)
					break;
			}
			else
			{
				// Nothing valid found 
				break;
			}	
		}

		// This is no an actual impact
		if(!FinalizedGroundHit.IsValidBlockingHit())
			return FMovementHitResult(EMovementImpactType::NoImpact);

		return FinalizedGroundHit;
	}

	/**
	 * Do we allow aligning our world up with this impacts normals?
	 */
	bool ShouldAlignWorldUpWithContact(FMovementHitResult Contact) const
	{
		if(!Contact.IsValidBlockingHit())
			return false;

		if(Contact.IsAnyGroundContact())
			return ShouldAlignWorldUpWithGround();

		if(Contact.IsWallImpact())
			return ShouldAlignWorldUpWithWall();

		if(Contact.IsCeilingImpact())
			return ShouldAlignWorldUpWithCeiling();

		return false;
	}

	bool ShouldAlignWorldUpWithGround() const
	{
		return false;
	}

	bool ShouldAlignWorldUpWithWall() const
	{
		return false;
	}

	bool ShouldAlignWorldUpWithCeiling() const
	{
		return false;
	}

	/**
	 * Called from the base resolvers whenever we hit anything, and then broadcasts HandleMovementImpact to be overridden in custom resolvers.
	 */
	protected bool HandleMovementImpactInternal(FMovementHitResult Hit, EMovementResolverAnyShapeTraceImpactType ImpactType) final
	{
		check(Hit.IsValidBlockingHit(), "Invalid hit passed into BroadcastMovementImpact. Always check IsValidBlockingHit() before calling this function!");
		check(HasMovementControl(), "We can only handle movement impacts on the control side!");

#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"HandleMovementImpact");
#endif

		AccumulatedImpacts.AddImpact(Hit);

		for(UMovementResolverExtension Extension : Extensions)
		{
#if !RELEASE
			FMovementResolverTemporalLogContextScope ExtensionScope(this, Extension.Class.Name);
#endif

			switch(Extension.PreHandleMovementImpact(Hit, ImpactType))
			{
				case EMovementResolverHandleMovementImpactResult::Continue:
					continue;

				case EMovementResolverHandleMovementImpactResult::Skip:
					return true;

				case EMovementResolverHandleMovementImpactResult::Finish:
				{
					StopResolving();
					return true;
				}
			}
		}

		switch(HandleMovementImpact(Hit, ImpactType))
		{
			case EMovementResolverHandleMovementImpactResult::Continue:
				return false;

			case EMovementResolverHandleMovementImpactResult::Skip:
				return true;

			case EMovementResolverHandleMovementImpactResult::Finish:
			{
				StopResolving();
				return true;
			}
		}
	}

	/**
	 * Called every time we sweep into something, be it an iteration or a ground sweep.
	 * @return How to handle the rest of this iteration.
	 */
	protected EMovementResolverHandleMovementImpactResult HandleMovementImpact(FMovementHitResult Hit, EMovementResolverAnyShapeTraceImpactType ImpactType)
	{
		return EMovementResolverHandleMovementImpactResult::Continue;
	}

	/**
	 * The different base resolvers have their own ways of deciding when they are done.
	 * Implementations of this will set the required values to end the move next iteration.
	 */
	protected void StopResolving()
	{
	}

	// For some reason, chaos is completely broken and still finds bad normals on scaled objects and edges.
	// So we need to line trace against the impact point, to find the correct impact normal
	protected void FixupTraceImpactNormal(FHitResult& Impact) const final
	{
		// Can't fix normals on an invalid hit
		if (!Impact.IsValidBlockingHit())
			return;

		const FVector InvertedTraceDir = -(Impact.TraceEnd - Impact.TraceStart).GetSafeNormal();
		const bool bNormalsAreBroken = InvertedTraceDir.DotProduct(Impact.Normal) < 1 - SMALL_NUMBER && Impact.ImpactNormal.DotProduct(Impact.Normal) < 0.707;
		if (!bNormalsAreBroken)
			return;

		// First we trace against the impact point using the normal 
		FHazeTraceTag TraceTag = GenerateTraceTag(n"QueryTraceEdgeValidation", n"1_of_2");
		FVector NormalValidation = QueryTraceEdgeValidation(Impact, FVector::ZeroVector, TraceTag);
		if(NormalValidation.IsNearlyZero())
			return;

		// We now compare the new trace if that normal is still wrong
		float NormalScore = Impact.Normal.DotProductLinear(InvertedTraceDir);
		float ImpactNormalScore = Impact.ImpactNormal.DotProductLinear(InvertedTraceDir);

		// If its still wrong, we need to trace again.
		// This time, we offset the trace using the 'bad' impact normal.
		// This will place us on the other side of the edge.
		if(NormalScore > ImpactNormalScore && Impact.ImpactNormal.DotProduct(NormalValidation) > 1 - SMALL_NUMBER)
		{
			TraceTag = GenerateTraceTag(n"QueryTraceEdgeValidation", n"2_of_2");
			FVector SecondNormalValidation = QueryTraceEdgeValidation(Impact, -Impact.ImpactNormal, TraceTag);
			// If this trace normal is pointing more towards the normal direction than the old trace,
			// we use this impacts normal instead.
			if (SecondNormalValidation.DotProduct(Impact.Normal) > NormalValidation.DotProduct(Impact.Normal))
			{
				NormalValidation = SecondNormalValidation;
			}
		}

		// Now, we compare if the validated normal is better than the original normal.
		// The closest one to the normal, will be used for the final result.
		if(!NormalValidation.Equals(Impact.ImpactNormal))
		{
			const float ValidationScore = NormalValidation.DotProductLinear(Impact.Normal) + NormalValidation.DotProductLinear(InvertedTraceDir);
			const float GroundTraceScore = Impact.ImpactNormal.DotProductLinear(Impact.Normal) + Impact.ImpactNormal.DotProductLinear(InvertedTraceDir);
			if (ValidationScore > GroundTraceScore)
			{
				Impact.ImpactNormal = NormalValidation;
			}
		}
	}

	private FVector QueryTraceEdgeValidation(FHitResult GroundHit, FVector Offset, FHazeTraceTag TraceTag) const
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"QueryTraceEdgeValidation");
#endif

		const FVector TraceStart = GroundHit.ImpactPoint + GroundHit.Normal + Offset;
		const FVector TraceEnd = GroundHit.ImpactPoint - GroundHit.Normal + Offset;

		FHitResult ValidationHit;
		FVector ValidationImpactLocation, ValidationImpactNormal;
		FName BoneName;
		const bool bHasFoundHit = GroundHit.Component.LineTraceComponent(
			TraceStart,
			TraceEnd,
			false,
			false,
			false,
			ValidationImpactLocation,
			ValidationImpactNormal,
			BoneName,
			ValidationHit);

		ValidationHit.bBlockingHit = bHasFoundHit;

#if !RELEASE
		ResolverTemporalLog.HitResult(
			TraceTag.ToString(),
			ValidationHit,
			FHazeTraceShape::MakeLine(),
			FVector::ZeroVector
		);
#endif

		if(!bHasFoundHit || ValidationHit.bStartPenetrating)
			return FVector::ZeroVector;

		return ValidationImpactNormal;
}

	protected FMovementHitResult GenerateDefaultMovementHitResult(FHitResult Hit, FVector WorldUp, float SafetyMargin, FHazeTraceTag TraceTag) const
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"GenerateDefaultMovementHitResult");
#endif

		FMovementHitResult Out(Hit, SafetyMargin);

		// No safety margin, nothing to pullback
		if(SafetyMargin > 0) 
			Out.ApplyPullback();

		ApplyImpactType(Out, WorldUp);
		ApplyWalkableStatus(Out);

#if !RELEASE
		Out.TraceTag = TraceTag;
#endif

		return Out;
	}

	protected FMovementHitResult GenerateDefaultGroundedState(FHitResult Hit, FVector WorldUp, FHazeTraceTag TraceTag, FVector CustomImpactNormal = FVector::ZeroVector, float FlatBottomRadius = 0) const
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"GenerateDefaultGroundedState");
#endif

		FMovementHitResult Out(Hit, InternalData.SafetyDistance.Y, FlatBottomRadius);
		Out.ApplyPullback();
		ApplyImpactType(Out, WorldUp, CustomImpactNormal);
		ApplyWalkableStatus(Out);

#if !RELEASE
		Out.TraceTag = TraceTag;
#endif

		return Out;
	}

	/**
	 * If we are hit by a moving actor, we need to make sure that we move out of it.
	 * This function will only resolve collisions with HazeActors that return a valid
	 * delta from TryGetRawTranslationDelta.
	 * @return true we didn't hit a moving actor, or successfully moved.
	 */
	protected bool ResolveHitByMovingActor(FHazeMovementTraceSettings& TraceSettings, const UPrimitiveComponent Component, const FVector& CurrentLocation, FVector& OutLocation) const
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"ResolveHitByMovingActor");
#endif

		AHazeActor Actor = Cast<AHazeActor>(Component.Owner);
		if(Actor == nullptr)
			return true;

		if(Component.Mobility != EComponentMobility::Movable)
			return true;

		// We hit a moving object, check if it is moving towards us

		FVector Delta;
		const bool bHasVelocity = Actor.TryGetRawLastFrameTranslationDelta(Delta);

		Delta *= 1.1;	// Go a little bit further than the delta, to decrease the chances of still penetrating the actor

		if(!bHasVelocity || Delta.IsNearlyZero())
			return false;	// The actor does not implement TryGetRawTranslationDelta, or didn't move this frame

		const FVector PreviousLocation = Component.WorldLocation - Delta;
		const FVector ToCurrent = CurrentLocation - PreviousLocation;

		if(ToCurrent.DotProduct(Delta) <= 0.0)
			return true;	// The actor is moving away, we don't need to resolve

        // Sweep in the direction the actor is traveling
		const float WholeDeltaDistance = Delta.Size();
		float RemainingDistance = WholeDeltaDistance;
		FMovementHitResult FollowVelocitySweep;
		FVector IterationLocation = CurrentLocation;
		FVector IterationDelta = Delta;

		while(RemainingDistance > KINDA_SMALL_NUMBER)
		{
			// Ignore the hit actor to allow moving away from it without getting a bad sweep
			TraceSettings.AddNextTraceIgnoredActor(Actor);

			// Sweep in the direction the actor is traveling
			const FHazeTraceTag TraceTag = GenerateTraceTag(n"HitMovingActor", n"FollowVelocity");
			FollowVelocitySweep = QueryShapeTrace(IterationLocation, IterationDelta, TraceTag);

			if(FollowVelocitySweep.bStartPenetrating)
			{
				// We failed to sweep out of the moving actor
				return false;
			}
			else if(FollowVelocitySweep.Time < 1.0)
			{
				// We hit something, redirect along the hit normal
				RemainingDistance -= FollowVelocitySweep.Distance;
				const FVector RedirectDir = IterationDelta.VectorPlaneProject(FollowVelocitySweep.Normal).GetSafeNormal();
				IterationLocation = FollowVelocitySweep.Location;

				// We need to adjust the redirect distance based on the angle
				float A = Delta.GetSafeNormal().DotProduct(RedirectDir) * Delta.Size();
				
				float NewDistanceDiff = FollowVelocitySweep.Distance / A;
				RemainingDistance += (NewDistanceDiff + 10.0);	// TODO: Tyko approves

				IterationDelta = RedirectDir * RemainingDistance;
			}
			else
			{
				// We didn't hit anything, this is a valid location
				break;
			}
		}

		if(!FollowVelocitySweep.bStartPenetrating)
		{
			const FVector MoveBackDir = -IterationDelta.GetSafeNormal();
			const FVector MoveBackDelta = MoveBackDir * Delta.Size();

			// If the sweep was successful, sweep back to see where we would hit the actor
			const FHazeTraceTag TraceTag = GenerateTraceTag(n"HitMovingActor", n"MoveBack");
			FMovementHitResult MoveBackSweep = QueryShapeTrace(FollowVelocitySweep.Location, MoveBackDelta, TraceTag);

			if(!MoveBackSweep.bStartPenetrating)
			{
				// Move to where the actor was hit
				OutLocation = MoveBackSweep.Location;
				return true;
			}
			else
			{
				// Fallback, the MoveBack sweep failed but we still have a better location
				OutLocation = FollowVelocitySweep.Location;
				return false;
			}
		}

		return false;	// We failed to sweep out of the moving actor, or back to it
	}

	// /**
	//  * Check if we are overlapping with anything, and if so, try to move out.
	//  */
	// protected FVector ResolveInitialOverlaps(FVector CurrentLocation, FQuat CurrentRotation) const
	// {
	// 	const FOverlapResultArray Overlaps = IterationTraceSettings.QueryOverlaps(CurrentLocation, FHazeTraceTag(n"InitialStartPenetratingOverlap"));

	// 	if(Overlaps.Num() == 0)
	// 		return CurrentLocation;

	// 	FVector TotalAccumulatedDelta = FVector::ZeroVector;
	// 	TArray<FVector> AccumulatedDeltas;
	// 	AccumulatedDeltas.Reserve(Overlaps.Num());

	// 	for(const FOverlapResult& Overlap : Overlaps)
	// 	{
	// 		if(Overlap.Component.GetMobility() != EComponentMobility::Movable)
	// 			continue;

	// 		const FVector Delta = Overlap.GetDepenetrationDelta(IterationTraceSettings.TraceShape.Shape, CurrentRotation, CurrentLocation);

	// 		// Accumulate the deltas from all overlaps
	// 		TotalAccumulatedDelta += Delta;
			
	// 		bool bFound = false;
	// 		for(FVector& AccumulatedDelta : AccumulatedDeltas)
	// 		{
	// 			// Add the delta to accumulated deltas that point in the same direction
	// 			if(Delta.DotProduct(AccumulatedDelta) > 0.0)
	// 			{
	// 				AccumulatedDelta += Delta;
	// 				bFound = true;
	// 			}
	// 		}

	// 		if(!bFound)
	// 			AccumulatedDeltas.Add(Delta);
	// 	}

	// 	// Get the largest delta, which is either the sum of
	// 	// all deltas, or one of the AccumulatedDeltas entries
	// 	FVector FinalDelta = TotalAccumulatedDelta;

	// 	for(const FVector& AccumulatedDelta : AccumulatedDeltas)
	// 	{
	// 		if(AccumulatedDelta.SizeSquared() > FinalDelta.SizeSquared())
	// 			FinalDelta = AccumulatedDelta;
	// 	}

	// 	return CurrentLocation + FinalDelta;
	// }

	/**
	 * Called when our movement trace was penetrating, allowing us to handle it before we depenetrate.
	 * @return If true, we will run the trace again, otherwise we let ResolveStartPenetrating run.
	 * FB TODO: This name is confusing with the function on extensions, but is more accurate than the one on extensions.
	 */
	protected bool PreResolveStartPenetrating(FMovementHitResult Impact)
	{
		return false;
	}

	/**
	 * Handle moving out of a bStartPenetrating hit.
	 * @param IterationHit The penetrating hit.
	 * @return The resolved location, ideally no longer penetrating.
	 */
	protected FVector ResolveStartPenetrating(FMovementHitResult IterationHit) const
	{
		check(IterationHit.bStartPenetrating);

#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"ResolveStartPenetrating");
#endif

		for(UMovementResolverExtension Extension : Extensions)
		{
#if !RELEASE
			FMovementResolverTemporalLogContextScope ExtensionScope(this, Extension.Class.Name);
#endif

			FVector ResolvedLocation;
			if(Extension.PreResolveStartPenetrating(IterationHit, ResolvedLocation))
				return ResolvedLocation;
		}

		FVector WantedDeltaMovement = IterationHit.TraceDirection * IterationHit.TraceLength;

		if(WantedDeltaMovement.IsNearlyZero())
			WantedDeltaMovement = -IterationHit.Normal;

		FVector FirstMTD = GetPenetrationAdjustment(IterationHit.InternalHitResult);

		if(FirstMTD.IsZero())
		{
			if(IterationHit.Component.Bounds.BoxExtent.IsZero())
				devError(f"ResolveStartPenetrating failed! The hit component ({IterationHit.Component}) is infinitely small, which makes it impossible to depenetrate! This should never occur in gameplay and needs to be investigated.");
			else if(IterationHit.Normal.IsZero() || IterationHit.ImpactNormal.IsZero())
				devError("ResolveStartPenetrating failed! The iteration hit normals are ZeroVector. This should never occur in gameplay and needs to be investigated.");
			else
				devError("ResolveStartPenetrating failed! This should never occur in gameplay and needs to be investigated.");
			
			// This is an invalid result, and should never occur in actual gameplay, and is thus not handled
			return IterationHit.TraceOrigin;
		}

		// First, try the suggested mtd result
		FHazeTraceTag TraceTag = GenerateTraceTag(n"Sweep_1_of_2", n"ResolveStartPenetrating");
		FMovementHitResult SweepTestOne = QueryShapeTrace(IterationHit.TraceOrigin + FirstMTD, WantedDeltaMovement, TraceTag);

		if(!SweepTestOne.bStartPenetrating)
		{
			return SweepTestOne.TraceOrigin;
		}

		// Combine two MTD results to get a new direction that gets out of multiple surfaces.
		// We also add the horizontal part of the MDT so make us trace from a location
		// further out and then trace back to where we wanted to be be from the beginning
		const FVector SecondMTD = GetPenetrationAdjustment(SweepTestOne.InternalHitResult);
		{
			FVector CombinedMTD = FirstMTD + SecondMTD;
			CombinedMTD += FirstMTD.VectorPlaneProject(CurrentWorldUp) + SecondMTD.ProjectOnToNormal(CurrentWorldUp);

			FVector TraceFrom = IterationHit.TraceOrigin + CombinedMTD;
			FVector TraceTo = IterationHit.TraceOrigin;
			FVector LastTraceDelta = TraceTo - TraceFrom;

			if(!LastTraceDelta.IsNearlyZero())
			{
				TraceTag = GenerateTraceTag(n"Sweep_2_of_2", n"ResolveStartPenetrating");
				FMovementHitResult LastSweep = QueryShapeTrace(TraceFrom, LastTraceDelta, TraceTag);

				if(!LastSweep.bStartPenetrating)
				{
					return LastSweep.TraceOrigin;
				}
			}
		}

		// If nothing works, apply the suggested mtd and eventually we will get out.
		return IterationHit.TraceOrigin + FirstMTD;
	}

	protected void ApplyImpactType(FMovementHitResult& HitResult, FVector WorldUp, FVector CustomImpactNormal = FVector::ZeroVector) const
	{
		HitResult.Type = GetImpactTypeFromHit(HitResult.InternalHitResult, WorldUp, CustomImpactNormal);
	}

	protected void ApplyWalkableStatus(FMovementHitResult& HitResult) const
	{
		if(InternalData.bForceAllGroundUnwalkable)
		{
			HitResult.bIsWalkable = false;
			return;
		}

		HitResult.bIsWalkable = ImpactHasWalkableStatus(HitResult.InternalHitResult);
	}

	protected bool ImpactHasWalkableStatus(FHitResult HitResult) const final
	{
		if(!HitResult.IsValidBlockingHit(true))
			return false;

		if(!HitResult.Component.HasTag(ComponentTags::Walkable))
			return false;

		return true;
	}

	/**
	 * Applies the edge information to the movement hit result.
	 * @param ForwardDirection Provide a valid direction to check if we are leaving the edge.
	 * @param bOverrideImpactNormal If our edge normal is in the same direction as the ForwardDirection, we generate a new impact normal for the HitResult to that is perpendicular to the edge normal.
	 * @return The Edge for HitResult
	*/
	protected FMovementEdge GetEdgeInformation(FMovementHitResult HitResult, FVector ForwardDirection, EMovementEdgeNormalRedirectType OverrideImpactNormalType) const
	{	
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"GetEdgeInformation");
#endif

		FMovementEdge Edge;
		Edge.Type = EMovementEdgeType::NoEdge;

		if(!HitResult.IsValidBlockingHit())
			return Edge;

		FVector TowardsCliffDirection = HitResult.Normal.VectorPlaneProject(CurrentWorldUp);
		if(TowardsCliffDirection.IsNearlyZero())
		{
			TowardsCliffDirection = HitResult.ImpactNormal.VectorPlaneProject(CurrentWorldUp);
			if(TowardsCliffDirection.IsNearlyZero())
			{
				// If this is impacts normals align with the the world up, we cant be on an edge yet
				Edge.Type = EMovementEdgeType::NoEdge;
				return Edge;
			}
		}

		TowardsCliffDirection.Normalize();

		if(InternalData.bConsiderImpactEdgeIfNormalsAngleHigherThanWalkableSlopeAngle)
		{
			if(HitResult.ImpactNormal.DotProduct(CurrentWorldUp) > 0)
			{
				const float AngleBetweenNormals = HitResult.ImpactNormal.GetAngleDegreesTo(HitResult.Normal);
				if(AngleBetweenNormals > InternalData.WalkableSlopeAngle)
				{
					// If the impact normal and normal are this misaligned, we must be barely holding on.
					// Consider it an edge, even if it might not be. It should be unstable, and we want to fall off of it.
					Edge.Type = EMovementEdgeType::Edge;

					Edge.EdgeNormal = HitResult.Normal.VectorPlaneProject(CurrentWorldUp).GetSafeNormal();
					if(Edge.EdgeNormal.IsNearlyZero())
						Edge.EdgeNormal = TowardsCliffDirection;

					Edge.GroundNormal = HitResult.ImpactNormal;
					Edge.bIsOnEmptySideOfLedge = true;
					Edge.Distance = FPlane(HitResult.ImpactPoint, Edge.EdgeNormal).PlaneDot(HitResult.Location);
					ApplyMovingPastEdge(Edge, HitResult, ForwardDirection, OverrideImpactNormalType);
					return Edge;
				}
			}
		}

#if !RELEASE
		ResolverTemporalLog.DirectionalArrow("TowardsCliffDirection", HitResult.ImpactPoint, TowardsCliffDirection * 100);
#endif

		const bool bIsFlat = HitResult.Normal.Parallel(HitResult.ImpactNormal);
		const bool bEdgeIsPeak = !bIsFlat && HitResult.Normal.DotProduct(CurrentWorldUp) > HitResult.ImpactNormal.DotProduct(CurrentWorldUp);

		const float EdgeSafety = InternalData.SafetyDistance.Y + 1;
		FMovementHitResult InnerHit;
		FMovementHitResult OuterHit;
		float TraceDistance = Math::Max(
			(HitResult.Location.Distance(HitResult.ImpactPoint) + 0.1) * 2,
			EdgeSafety * 3)
		;

		if(bEdgeIsPeak)
		{
			// We are standing on an edge pointing up towards the sky
			// Trace on either side of the hit

			const FVector UpOffset = (CurrentWorldUp * EdgeSafety);
			const FVector EdgeOffset = TowardsCliffDirection * EdgeSafety;
			const FVector TraceDelta = -CurrentWorldUp * TraceDistance;

			// Trace on the ground side of the peak
			{
				FVector TraceFrom = HitResult.ImpactPoint + UpOffset - EdgeOffset;
				InnerHit = QueryLineTrace(TraceFrom, TraceDelta, GenerateTraceTag(n"InnerHit"));
			}

			// Trace on the cliff side of the beak
			{
				FVector TraceFrom = HitResult.ImpactPoint + UpOffset + EdgeOffset;
				OuterHit = QueryLineTrace(TraceFrom, TraceDelta, GenerateTraceTag(n"OuterHit"));
			}

			if(InnerHit.IsWalkableGroundContact() && OuterHit.IsWalkableGroundContact())
			{
				// If we hit ground on both sides of the peak, then this is not edge
				return Edge;
			}
		}
		else
		{
			// We might be standing on a horizontal cliff
			const FVector UpOffset = (HitResult.Normal * EdgeSafety);
			const FVector EdgeOffset = TowardsCliffDirection * EdgeSafety;
			FVector TraceDelta = -HitResult.Normal * TraceDistance;

			// First, we trace in the direction pointing in the opposite direction of the impact normal.
			// Making this position, the closest to the capsule center
			{
				FVector TraceFrom = HitResult.ImpactPoint + UpOffset - EdgeOffset;
				InnerHit = QueryLineTrace(TraceFrom, TraceDelta, GenerateTraceTag(n"InnerHit"));
			}

			// We trace where we expect the empty side to be back towards the impact point
			// to determine the edge normal
			{
				FVector TraceFrom = HitResult.ImpactPoint + UpOffset + EdgeOffset;
				OuterHit = QueryLineTrace(TraceFrom, TraceDelta, GenerateTraceTag(n"OuterHit"));
			}
		}

		if(InnerHit.IsAnyGroundContact() && OuterHit.IsAnyGroundContact())
		{
			// If we hit ground on both sides, then this is not edge
			return Edge;
		}

		if(InnerHit.IsValidBlockingHit() && OuterHit.IsValidBlockingHit())
		{
			// Both traces hit
			if(OuterHit.ImpactNormal.DotProduct(InnerHit.ImpactNormal) > 1 - KINDA_SMALL_NUMBER)
			{
				// Same normals can't be edges
				Edge.Type = EMovementEdgeType::NoEdge;
				Edge.EdgeNormal = OuterHit.Normal;
				Edge.GroundNormal = InnerHit.Normal;
				return Edge;
			}
		}

		if(!InnerHit.bStartPenetrating && OuterHit.bStartPenetrating)
		{
			// Redo outer hit from the inner hit origin
			FVector TraceDelta = OuterHit.TraceOrigin - InnerHit.TraceOrigin;
			OuterHit = QueryLineTrace(InnerHit.TraceOrigin, TraceDelta, GenerateTraceTag(n"OuterHit_FromInnerHitOrigin"));
		}
		else if(InnerHit.bStartPenetrating && !OuterHit.bStartPenetrating)
		{
			// Redo inner hit from the outer hit origin
			FVector TraceDelta = InnerHit.TraceOrigin - OuterHit.TraceOrigin;
			InnerHit = QueryLineTrace(OuterHit.TraceOrigin, TraceDelta, GenerateTraceTag(n"InnerHit_FromOuterHitOrigin"));
		}

		if(!InnerHit.IsValidBlockingHit() && !OuterHit.IsValidBlockingHit())
		{
			// None of the traces hit, or were both invalid
			return Edge;
		}

		// Swap the hits so that the Inner hit is always the ground hit (or most vertical)
		bool bSwapHits = false;
		if(!InnerHit.IsAnyGroundContact() && OuterHit.IsAnyGroundContact())
			bSwapHits = true;
		else if(InnerHit.IsValidBlockingHit() && OuterHit.IsValidBlockingHit())
		{
			if(InnerHit.Normal.DotProduct(CurrentWorldUp) < OuterHit.Normal.DotProduct(CurrentWorldUp))
				bSwapHits = true;
		}

		if(bSwapHits)
		{
			FMovementHitResult Temp = InnerHit;
			InnerHit = OuterHit;
			OuterHit = Temp;
		}

		if(InnerHit.IsAnyGroundContact() != OuterHit.IsAnyGroundContact())
		{
			// Either both traces hit something, but only one is ground ...
			// ... or one hit and the other didn't
			// Either way, this means that one of them hit the top, and the other is a cliff
			Edge.Type = EMovementEdgeType::Edge;

			Edge.GroundNormal = InnerHit.Normal;

			if(OuterHit.IsValidBlockingHit())
			{
				Edge.EdgeNormal = OuterHit.Normal;
			}
			else if(bEdgeIsPeak)
			{
				Edge.EdgeNormal = HitResult.Normal.VectorPlaneProject(Edge.GroundNormal).GetSafeNormal();
				if(Edge.EdgeNormal.IsNearlyZero())
				{
					Edge.EdgeNormal = TowardsCliffDirection.VectorPlaneProject(Edge.GroundNormal).GetSafeNormal();
				}
			}
			else
			{
				Edge.EdgeNormal = TowardsCliffDirection.VectorPlaneProject(Edge.GroundNormal).GetSafeNormal();
			}

			if(Edge.GroundNormal.DotProduct(Edge.EdgeNormal) > 1 - KINDA_SMALL_NUMBER)
			{
				// Same normals can't be edges
				Edge.Type = EMovementEdgeType::NoEdge;
				return Edge;
			}

			const FPlane EdgePlane = FPlane(HitResult.ImpactPoint, Edge.EdgeNormal);
			const FVector ShapeLocation = IterationState.ConvertLocationToShapeCenterLocation(HitResult.Location, IterationTraceSettings);
			Edge.Distance = EdgePlane.PlaneDot(ShapeLocation);
			Edge.bIsOnEmptySideOfLedge = Edge.Distance > 0;

			ApplyMovingPastEdge(Edge, HitResult, ForwardDirection, OverrideImpactNormalType);
			return Edge;
		}

		if(InnerHit.IsValidBlockingHit() == OuterHit.IsValidBlockingHit())
		{
			// Both traces hit
			// We need to check the angle between them to determine if it is great enough
			float Angle = InnerHit.Normal.GetAngleDegreesTo(OuterHit.Normal);
			if(Angle > InternalData.WalkableSlopeAngle)
			{
				// The angle is greater than we could walk over, meaning that this should be an edge
				Edge.Type = EMovementEdgeType::Edge;
				Edge.Distance = (HitResult.ImpactPoint - HitResult.Location).VectorPlaneProject(CurrentWorldUp).Size();

				Edge.GroundNormal = InnerHit.Normal;
				Edge.EdgeNormal = OuterHit.Normal;

				if(Edge.EdgeNormal.IsNearlyZero())
				{
					Edge.EdgeNormal = (InnerHit.Normal + OuterHit.Normal).GetSafeNormal();
					Edge.GroundNormal = Edge.EdgeNormal;
				}

				ApplyMovingPastEdge(Edge, HitResult, ForwardDirection, OverrideImpactNormalType);
				return Edge;
			}
		}

		// This is not an edge
		check(!Edge.IsEdge());
		return Edge;
	}

	/**
	 * Determine if we are moving past an edge or not.
	 */
	protected void ApplyMovingPastEdge(FMovementEdge& Edge, FMovementHitResult HitResult, FVector ForwardDirection, EMovementEdgeNormalRedirectType OverrideImpactNormalType) const
	{
		if(!Edge.IsEdge())
			return;

#if EDITOR
		MovementCheck(Edge.IsValidEdge());
#endif

		// If we are moving towards the edge direction, that counts as leaving the edge
		if(ForwardDirection.DotProduct(Edge.EdgeNormal.VectorPlaneProject(CurrentWorldUp)) > 0)
		{
			Edge.bMovingPastEdge = true;

			switch(OverrideImpactNormalType)
			{
				case EMovementEdgeNormalRedirectType::None:
					break;

				case EMovementEdgeNormalRedirectType::Soft:
				{
					FVector NewImpactNormal = CurrentWorldUp.VectorPlaneProject(Edge.EdgeNormal).GetSafeNormal();
					NewImpactNormal += HitResult.ImpactNormal;
					Edge.OverrideRedirectNormal = NewImpactNormal.GetSafeNormal();
					break;
				}

				case EMovementEdgeNormalRedirectType::Hard:
				{
					Edge.OverrideRedirectNormal = CurrentWorldUp.VectorPlaneProject(Edge.EdgeNormal).GetSafeNormal();
					break;
				}
			}
		}
		else
		{
			FVector ImpactDir = HitResult.ImpactNormal.VectorPlaneProject(CurrentWorldUp);
			if(ImpactDir.IsNearlyZero())
				return;

			if(HitResult.ImpactNormal.DotProduct(CurrentWorldUp) > 0)
				return;	// The edge normal is pointing towards our world up, so it should be considered ground and not an edge

			if(ForwardDirection.DotProduct(ImpactDir) <= 0)
				return;
			
			Edge.bMovingPastEdge = true;

			switch(OverrideImpactNormalType)
			{
				case EMovementEdgeNormalRedirectType::None:
					break;

				case EMovementEdgeNormalRedirectType::Soft:
				{
					FVector NewImpactNormal = CurrentWorldUp.VectorPlaneProject(HitResult.ImpactNormal).GetSafeNormal();
					NewImpactNormal += HitResult.Normal;
					Edge.OverrideRedirectNormal = NewImpactNormal.GetSafeNormal();
					break;
				}

				case EMovementEdgeNormalRedirectType::Hard:
				{
					Edge.OverrideRedirectNormal = CurrentWorldUp.VectorPlaneProject(HitResult.ImpactNormal).GetSafeNormal();
					break;
				}
			}
		}
	}

	protected bool IsEdgeUnstable(FMovementHitResult HitResult) const
	{
		if(!HitResult.EdgeResult.IsEdge())
			return false;
		
		if(!HitResult.EdgeResult.IsUnstable())
			return false;

		if(HitResult.IsStepupGroundContact())
			return false;

		return true;
	}

	protected bool IsLeavingEdgeResult(FMovementEdge EdgeResult) const
	{
		if(!EdgeResult.IsEdge())
			return false;

		if(!EdgeResult.bMovingPastEdge)
			return false;

		if(EdgeResult.UnstableDistance >= 0)
		{
			// Tyko had this, but I don't know why. In my mind, a stable edge does not mean we are not leaving it
			if(!EdgeResult.IsUnstable())
				return false;
		}

		return true;
	}

	protected bool IsLeavingEdge(FMovementHitResult HitResult) const
	{
		if(!IsLeavingEdgeResult(HitResult.EdgeResult))
			return false;
		
		if(HitResult.IsStepupGroundContact())
			return false;

		return true;
	}

	protected EMovementImpactType GetImpactTypeFromHit(FHitResult HitResult, FVector WorldUp, FVector CustomImpactNormal = FVector::ZeroVector) const 
	{
		if(HitResult.bStartPenetrating)
		{
			return EMovementImpactType::Invalid;
		}

		// Have no actor will make us move right trough the object.
		// Its either a BSP or the actor has been destroyed.
		if(!HitResult.bBlockingHit)
		{
			return EMovementImpactType::NoImpact;
		}

		// If we are a capsule, check what side of the capsule was hit
		const EMovementCapsuleImpactSide CapsuleHitSide = GetCapsuleImpactType(HitResult);

		const FVector ImpactNormal = CustomImpactNormal.IsUnit() ? CustomImpactNormal : GetNormalForImpactTypeGeneration(HitResult);

		const float ImpactAngle = CalculateSlopeAngle(ImpactNormal, WorldUp);

		const float HitResultWalkableSlopeAngle = InternalData.WalkableSlopeAngle >= 0 ? HitResult.Component.GetWalkableSlopeAngle(InternalData.WalkableSlopeAngle) : -1;

		if(HitResultWalkableSlopeAngle >= 0 && ImpactAngle < HitResultWalkableSlopeAngle)
		{
			// If we are a capsule, it's impossible for us to find ground with a side ...
			if(CapsuleHitSide == EMovementCapsuleImpactSide::Side)
				return EMovementImpactType::Wall;
			// ... or top hit
			if(CapsuleHitSide == EMovementCapsuleImpactSide::Top)
				return EMovementImpactType::Ceiling;

			return EMovementImpactType::Ground;
		}

		const float CeilingAngle = InternalData.CeilingAngle;
		
		if(ImpactNormal.DotProduct(-WorldUp) > Math::Cos(Math::DegreesToRadians(CeilingAngle)))
		{
			return EMovementImpactType::Ceiling;
		}

		return EMovementImpactType::Wall;
	}

	protected float CalculateSlopeAngle(FVector ImpactNormal, FVector WorldUp) const
	{
		float ImpactAngle = WorldUp.GetAngleDegreesTo(ImpactNormal);

		// We might also want to use the ActorUp for checking the walkable slope angle.
		// Can help with falling onto a sloped surface if the actor is not vertically aligned.
		if(InternalData.bAlsoUseActorUpForWalkableSlopeAngle)
		{
			// Use the lowest angle, if any of them is valid we want it to be ground
			ImpactAngle = Math::Min(ImpactAngle, IterationState.CurrentRotation.UpVector.GetAngleDegreesTo(ImpactNormal));
		}

		return ImpactAngle;
	}

	protected void GetSafetyForTraceDelta(FVector DeltaToTrace, FVector& OutExtraDelta, float& OutSafetyDistance) const
	{
		const FVector TraceDir = DeltaToTrace.GetSafeNormal();
		const float SafetyMarginYAlpha = TraceDir.DotProductLinear(CurrentWorldUp);
		OutSafetyDistance = Math::Lerp(InternalData.SafetyDistance.X, InternalData.SafetyDistance.Y, SafetyMarginYAlpha);
		OutExtraDelta = TraceDir * OutSafetyDistance;
	}

	protected FVector GetNormalForImpactTypeGeneration(FHitResult HitResult) const
	{
		return HitResult.ImpactNormal;
	}

	EMovementShapeType GetMovementShapeType() const
	{
		if (!TraceShape.IsValid())
			return EMovementShapeType::Invalid;

		if (TraceShape.IsLine())
			return EMovementShapeType::Invalid;

		switch (TraceShape.Shape.ShapeType)
		{
			case ECollisionShape::Line:
				return EMovementShapeType::Invalid;

			case ECollisionShape::Box:
				return EMovementShapeType::Box;

			case ECollisionShape::Sphere:
				return EMovementShapeType::Sphere;

			case ECollisionShape::Capsule:
			{
				if (TraceShape.Shape.CapsuleHalfHeight <= TraceShape.Shape.CapsuleRadius)
					return EMovementShapeType::Sphere;

				const FVector ShapeUp = TraceShape.Orientation.GetUpVector();
				const float ShapeAlignment = ShapeUp.DotProduct(IterationState.WorldUp);
				const bool bShapeAlignedWithWorldUp = Math::Abs(ShapeAlignment) >= 1.0 - KINDA_SMALL_NUMBER;
				if (bShapeAlignedWithWorldUp)
				{
					if (ShapeAlignment > 0)
					{
						return EMovementShapeType::AlignedCapsule;
					}
					else
					{
						return EMovementShapeType::FlippedCapsule;
					}
				}
				else
				{
					return EMovementShapeType::NonAlignedCapsule;
				}
			}
		}
	}

	bool CanUseFlatBottomCapsule() const
	{
		switch(GetMovementShapeType())
		{
			case EMovementShapeType::Invalid:
				return false;

			case EMovementShapeType::Sphere:
				return true;

			case EMovementShapeType::AlignedCapsule:
				return true;

			case EMovementShapeType::FlippedCapsule:
				return true;

			case EMovementShapeType::NonAlignedCapsule:
				return false;

			case EMovementShapeType::Box:
				return false;
		}
	}

	protected EMovementCapsuleImpactSide GetCapsuleImpactType(FHitResult HitResult) const
	{
		// We can only determine the impact type like this if the shape is a WorldUp aligned capsule
		if(GetMovementShapeType() != EMovementShapeType::AlignedCapsule)
			return EMovementCapsuleImpactSide::Unset;

		const FQuat ShapeRotation = IterationTraceSettings.GetCollisionShapeWorldRotation();
		const FVector ShapeLocation = HitResult.Location + IterationTraceSettings.CollisionShapeOffset;
		const FTransform ShapeTransform = FTransform(ShapeRotation, ShapeLocation);

		const FVector RelativeToShapeLocation = ShapeTransform.InverseTransformPositionNoScale(HitResult.ImpactPoint);
		const float CapsuleSideHeight = TraceShape.Shape.CapsuleHalfHeight - TraceShape.Shape.CapsuleRadius;

		if(Math::Abs(RelativeToShapeLocation.Z) < CapsuleSideHeight)
		{
			// We hit the edge of the capsule, the normal should be along the capsule axis plane
			return EMovementCapsuleImpactSide::Side;
		}

		if(RelativeToShapeLocation.Z > CapsuleSideHeight)
			return EMovementCapsuleImpactSide::Top;
		else
			return EMovementCapsuleImpactSide::Bottom;
	}

	protected bool ShouldValidateRemoteSideGroundPosition() const
	{
		bool bValidateGrounded = false;
		if(!InternalData.CustomStatus.Find(EMovementCustomStatus::RemoteSideEvaluateGround, bValidateGrounded))
			return false;
		return bValidateGrounded;
	}

	// protected FMovementDelta GetTerminalVelocityClampedDelta(FMovementDelta Delta) const
	// {
	// 	// Clamp the vertical velocity
	// 	FMovementDelta NewVertical = Delta.GetVerticalPart(CurrentWorldUp);
	// 	if(InternalData.TerminalVelocity >= 0 && NewVertical.Delta.DotProduct(CurrentWorldUp) < 0)
	// 	{	
	// 		NewVertical.ClampToMaxVelocitySize(InternalData.TerminalVelocity);
	// 		return Delta.GetHorizontalPart(CurrentWorldUp) + NewVertical;
	// 	}

	// 	return Delta;
	// }

	/**
	 * Called immediately after Resolve(), and before ApplyResolvedData().
	 * Data has not been applied on the actor or movement component yet, but the resolver should be in its final state.
	 */
	void PostResolve()
	{
#if !RELEASE
		ResolverTemporalLog.PostResolve();
#endif
	}

	protected void ApplyResolvedData(UHazeMovementComponent MovementComponent)
	{
		for(UMovementResolverExtension Extension : Extensions)
		{
#if !RELEASE
			FMovementResolverTemporalLogContextScope ExtensionScope(this, Extension.Class.Name);
#endif

			Extension.PreApplyResolvedData(MovementComponent);
		}
	}

	protected void PostApplyResolvedData(UHazeMovementComponent MovementComponent)
	{
		for(UMovementResolverExtension Extension : Extensions)
		{
#if !RELEASE
			FMovementResolverTemporalLogContextScope ExtensionScope(this, Extension.Class.Name);
#endif
			Extension.PostApplyResolvedData(MovementComponent);
		}
	}

#if !RELEASE
	protected void DebugValidateMoveAmount(FVector DeltaToMove, float MaxSubStepTraceLength, int BonusSubStepIterations, FString Reason)
	{
		if(IsApplyingInParallel())
			return;
		
		const float PendingDeltaSize = DeltaToMove.Size();
		const int UpcomingIterations = Math::CeilToInt(PendingDeltaSize / MaxSubStepTraceLength);
		const int AvailableIterations = InternalData.MaxRedirectIterations + BonusSubStepIterations;
		devCheck(AvailableIterations > UpcomingIterations, 
			f"This moves requires sub stepping because of {Reason}. Max movement iteration count is {InternalData.MaxRedirectIterations} but the move will require at least {UpcomingIterations - BonusSubStepIterations}." + 
			f"\nMake sure the move is shorter" +
			f"\nor increase the amount of valid iterations"+
			f"\nor turn of {Reason} that require sub stepping");
		
	}

	protected bool CanTemporalLog() const
	{
#if EDITOR
		if(InternalData.bIsEditorRerunData)
			return false;
#endif

		if(IsApplyingInParallel())
			return false;

		return true;
	}

	/**
	 * Owner/Movement, associated with the owning MovementComponent
	 */
	FTemporalLog GetTemporalLog() const
	{
		check(CanTemporalLog(), "Never temporal log during reruns or while applying in parallel! Always check CanTemporalLog() before calling GetTemporalLog().");
		return InternalData.GetTemporalLog();
	}
#endif
};
