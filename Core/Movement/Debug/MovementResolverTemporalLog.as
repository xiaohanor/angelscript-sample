#if !RELEASE
enum EMovementResolverTemporalLogPhase
{
	PrepareResolver,
	Iterating,
	PostResolve,
};

/**
 * Interface for logging during a MovementResolver resolve.
 * This enables us to log while we iterate, while not doing so when in reruns, or in builds.
 * It's a UObject so that we can call it from const MovementResolver functions 🤡
 */
class UMovementResolverTemporalLog
{
	access BaseMovementResolver = private, UBaseMovementResolver;
	access ContextScope = private, FMovementResolverTemporalLogContextScope;

	/**
	 * Per Resolve
	 */

	private const UBaseMovementResolver Resolver;
	private bool bIsRerun = false;

	private FTemporalLog TemporalLog;
	private EMovementResolverTemporalLogPhase Phase;

	// Index to keep values logged outside contexts sorted
	private int LoggedWithoutContextCount = 0;
	private int LoggedValuesCount = 0;

	// FB TODO: Make this generic? Don't want to overcomplicate it for now
	private TArray<FMovementResolverTemporalLogLoggedMovementHitEntry> LoggedMovementHits;

	/**
	 * Current contexts
	 * We keep them around even when they have gone out of scope, because if the next scope added is 
	 */
	private TArray<FMovementResolverTemporalLogContext> ContextStack;

	// The context ID increments every time a new context is added to keep the contexts sorted
	private int CurrentContextID = 0;

	private int NumLineTraces = 0;
	private int NumShapeTraces = 0;
	private int NumOverlaps = 0;

	/**
	 * Per Iteration
	 */

	private int IterationCount = 0;
	private FString IterationCategory;

	access:BaseMovementResolver
	void PrepareResolve(const UHazeMovementComponent MoveComp, const UBaseMovementResolver InResolver)
	{
		Phase = EMovementResolverTemporalLogPhase::PrepareResolver;
		
		Resolver = InResolver;
		bIsRerun = MoveComp.IsPerformingDebugRerun();

		if(!CanLog())
			return;
		
		TemporalLog = MoveComp.GetTemporalLog().Page(InResolver.TemporalLogPageName);
		LoggedWithoutContextCount = 0;
		LoggedValuesCount = 0;
		LoggedMovementHits.Reset();

		ContextStack.Empty();
		CurrentContextID = 0;

		NumLineTraces = 0;
		NumShapeTraces = 0;
		NumOverlaps = 0;

		IterationCount = 0;
	}

	void SetTemporalLog(FTemporalLog InTemporalLog)
	{
		if(!CanLog())
			return;

		TemporalLog = InTemporalLog;
	}

	access:BaseMovementResolver
	void PrepareIteration()
	{
		if(!CanLog())
			return;

		Phase = EMovementResolverTemporalLogPhase::Iterating;
		LoggedMovementHits.Reset();

		if(Resolver.IterationCount <= IterationCount)
		{
			IterationCount++;
			IterationCategory = f"Iteration {IterationCount} (Resolver Iteration: {Resolver.IterationCount})";
		}
		else
		{
			IterationCount = Resolver.IterationCount;
			IterationCategory = f"Iteration {IterationCount}";
		}

		if(Resolver.IterationCount > 1)
		{
			const FTemporalLog MovementTemporalLog = Resolver.GetTemporalLog();

			for(int i = 0; i < Resolver.Extensions.Num(); i++)
			{
				UMovementResolverExtension Extension = Resolver.Extensions[i];
				FTemporalLog ExtensionLog = Extension.GetTemporalLogPage(MovementTemporalLog, i + 1);
				ExtensionLog.Value("ExtensionClass", Extension.Class);
				FTemporalLog ExtensionFinalLog = ExtensionLog.Section(f"Iteration {Resolver.IterationCount - 1}", IterationCount - 1);
				Extension.LogPostIteration(ExtensionFinalLog);
			}
		}
	}

	access:BaseMovementResolver
	void PostResolve()
	{
		Phase = EMovementResolverTemporalLogPhase::PostResolve;
		LoggedMovementHits.Reset();

		TemporalLog.CustomStatus("Iterations", f"{IterationCount - 1}/{Resolver.MaxRedirectIterations}");

		FTemporalLog FinalLog = TemporalLog.Section("Final", 999);
		FinalLog.Value("Num Line Traces", NumLineTraces);
		FinalLog.Value("Num Shape Traces", NumShapeTraces);
		FinalLog.Value("Num Overlaps", NumOverlaps);
	}

	private FTemporalLog GetPhaseLog() const
	{
		switch(Phase)
		{
			case EMovementResolverTemporalLogPhase::PrepareResolver:
				return TemporalLog.Section("PrepareResolver", -999);

			case EMovementResolverTemporalLogPhase::Iterating:
				return TemporalLog.Section(IterationCategory, Resolver.IterationCount, true);

			case EMovementResolverTemporalLogPhase::PostResolve:
				return TemporalLog.Section("PostResolve", 999);
		}
	}

	private FTemporalLog GetSectionLog(FString InValueName = "") const
	{
		FTemporalLog Log = GetPhaseLog();
		AppendContextSections(Log);
		return Log.Section(InValueName, LoggedValuesCount, true);
	}

	private bool CanLog() const
	{
		if(bIsRerun)
			return false;

		return true;
	}

	private bool HasAnyValidContexts() const
	{
		for(int i = ContextStack.Num() - 1; i >= 0; i--)
		{
			if(ContextStack[i].Instigators <= 0)
				continue;

			return true;
		}

		return false;
	}

	private void AppendContextSections(FTemporalLog& Log) const
	{
		for(int i = 0; i < ContextStack.Num(); i++)
		{
			const FMovementResolverTemporalLogContext& Context = ContextStack[i];
			if(Context.Instigators <= 0)
				break;

			Log = Log.Section(Context.Name.ToString(), Context.ContextID, true);
		}
	}

	private FMovementResolverTemporalLogContext& GetTopValidContext()
	{
		for(int i = ContextStack.Num() - 1; i >= 0; i--)
		{
			if(ContextStack[i].Instigators <= 0)
				continue;

			return ContextStack[i];
		}

		check(false);
		return ContextStack.Last();
	}

	private FMovementResolverTemporalLogContext GetTopValidContext() const
	{
		for(int i = ContextStack.Num() - 1; i >= 0; i--)
		{
			if(ContextStack[i].Instigators <= 0)
				continue;

			return ContextStack[i];
		}

		check(false);
		return ContextStack.Last();
	}

	private bool ExistsInContextStack(FName InContextName) const
	{
		for(int i = ContextStack.Num() - 1; i >= 0; i--)
		{
			if(ContextStack[i].Name == InContextName)
				return true;
		}

		return false;
	}

	private FMovementResolverTemporalLogContext& FindContext(FName InContextName)
	{
		for(int i = ContextStack.Num() - 1; i >= 0; i--)
		{
			if(ContextStack[i].Name == InContextName)
				return ContextStack[i];
		}

		check(false);
		return ContextStack.Last();
	}

	private bool IsTopValidContext(FName InContextName) const
	{
		for(int i = ContextStack.Num() - 1; i >= 0; i--)
		{
			if(ContextStack[i].Instigators <= 0)
				continue;

			return ContextStack[i].Name == InContextName;
		}

		return false;
	}

	private void RemoveInvalidContexts()
	{
		for(int i = ContextStack.Num() - 1; i >= 0; i--)
		{
			if(ContextStack[i].Instigators <= 0)
				ContextStack.RemoveAt(i);
		}
	}

	access:ContextScope
	void PushContext(FName InContextName)
	{
		if(IsTopValidContext(InContextName))
		{
			// Our context name is still in the context stack, add us as an instigator to keep the context alive until we go out of scope
			FMovementResolverTemporalLogContext& ExistingContext = FindContext(InContextName);
			ExistingContext.Instigators++;
		}
		else
		{
			// Add ourselves as the top context
			ContextStack.Add(FMovementResolverTemporalLogContext(InContextName, CurrentContextID));
			CurrentContextID++;
		}

		// Remove any other contexts that are invalid
		RemoveInvalidContexts();
	}

	access:ContextScope
	void PopContext(FName InContextName)
	{
		check(!ContextStack.IsEmpty());
		check(IsTopValidContext(InContextName));

		FMovementResolverTemporalLogContext& TopContext = GetTopValidContext();
		TopContext.Instigators--;
		check(TopContext.Instigators >= 0, "It should never be possible for Instigators to drop below 0");

		// We don't remove the context here to allow child classes reusing contexts created in parent classes when overriding functions
	}

	private void IncrementContextCount()
	{
		check(HasAnyValidContexts());
		FMovementResolverTemporalLogContext& TopContext = GetTopValidContext();
		TopContext.LoggedInContextCount++;
	}

	private bool FindLoggedMovementHitEntry(FHazeTraceTag InTraceTag, FMovementResolverTemporalLogLoggedMovementHitEntry&out OutMovementHitEntry) const
	{
		for(int i = LoggedMovementHits.Num() - 1; i >= 0; i--)
		{
			FMovementResolverTemporalLogLoggedMovementHitEntry LoggedMovementHit = LoggedMovementHits[i];

			if(LoggedMovementHit.TraceTag.Tag != InTraceTag.Tag)
				continue;

			OutMovementHitEntry = LoggedMovementHit;
			return true;
		}

		return false;
	}

	private void MarkMovementHitEntryOverwritten(FHazeTraceTag InTraceTag)
	{
		for(int i = LoggedMovementHits.Num() - 1; i >= 0; i--)
		{
			FMovementResolverTemporalLogLoggedMovementHitEntry& LoggedMovementHit = LoggedMovementHits[i];

			if(LoggedMovementHit.TraceTag.Tag != InTraceTag.Tag)
				continue;

			check(!LoggedMovementHit.bOverwritten);
			LoggedMovementHit.bOverwritten = true;
			return;
		}
	}

	private int GetTotalTraceCount()
	{
		return NumLineTraces + NumShapeTraces + NumOverlaps;
	}

	private void PreValueLogged()
	{
		LoggedValuesCount++;

		if(!HasAnyValidContexts())
			LoggedWithoutContextCount++;
		else
			IncrementContextCount();
	}

	void Value(FString InName, const UObject InValue)
	{
		if(!CanLog())
			return;

		PreValueLogged();

		FTemporalLog ValueLog = GetSectionLog();
		ValueLog.Value(InName, InValue);
	}

	void Value(FString InName, float InValue)
	{
		if(!CanLog())
			return;

		PreValueLogged();

		FTemporalLog ValueLog = GetSectionLog();
		ValueLog.Value(InName, InValue);
	}

	void Value(FString InName, int InValue)
	{
		if(!CanLog())
			return;

		PreValueLogged();

		FTemporalLog ValueLog = GetSectionLog();
		ValueLog.Value(InName, InValue);
	}

	void Value(FString InName, bool bInValue)
	{
		if(!CanLog())
			return;

		PreValueLogged();

		FTemporalLog ValueLog = GetSectionLog();
		ValueLog.Value(InName, bInValue);
	}

	void Value(FString InName, FString InValue)
	{
		if(!CanLog())
			return;

		PreValueLogged();

		FTemporalLog ValueLog = GetSectionLog();
		ValueLog.Value(InName, InValue);
	}

	void HitResult(
		FString InName,
		FHitResult InHitResult,
		FHazeTraceShape InTraceShape,
		FVector CollisionShapeOffset)
	{
		if(!CanLog())
			return;

		PreValueLogged();

		// FB TODO: Better way of handling shape offset on hit results?
		FHitResult HitResult = InHitResult;
		HitResult.Location += CollisionShapeOffset;
		HitResult.TraceStart += CollisionShapeOffset;
		HitResult.TraceEnd += CollisionShapeOffset;

		FTemporalLog HitResultLog = GetSectionLog();

		HitResultLog.HitResults(
			InName,
			HitResult,
			InTraceShape,
		);

		if(InTraceShape.IsLine())
			NumLineTraces++;
		else
			NumShapeTraces++;
	}

	void MovementHit(
		FMovementHitResult MovementHit,
		FHazeTraceShape TraceShape,
		FVector CollisionShapeOffset)
	{
		if(!CanLog())
			return;

		PreValueLogged();

		if(!ensure(MovementHit.TraceTag.Tag != NAME_None, "Tried to log a MovementHit with an invalid trace tag!"))
			return;

		const FTemporalLog SectionLog = GetSectionLog(MovementHit.TraceTag.ToString());

		LogMovementHit(SectionLog, MovementHit, TraceShape, CollisionShapeOffset);

		if(TraceShape.IsLine())
			NumLineTraces++;
		else
			NumShapeTraces++;
		
		const FMovementResolverTemporalLogLoggedMovementHitEntry LoggedMovementHit(
			SectionLog,
			MovementHit.TraceTag,
			TraceShape,
			CollisionShapeOffset,
			MovementHit.ConvertToHitResult()
		);

		LoggedMovementHits.Add(LoggedMovementHit);
	}

	private void LogMovementHit(
		FTemporalLog SectionLog,
		FMovementHitResult MovementHit,
		FHazeTraceShape TraceShape,
		FVector CollisionShapeOffset) const
	{
		SectionLog.MovementHit(
			MovementHit.TraceTag.ToString(),
			MovementHit,
			TraceShape,
			CollisionShapeOffset
		);
	}

	/**
	 * After modifying a FMovementHitResult that has already been logged, we may want to overwrite it.
	 */
	void OverwriteMovementHit(FMovementHitResult NewMovementHit)
	{
		if(!CanLog())
			return;

		FMovementResolverTemporalLogLoggedMovementHitEntry LoggedMovementHit;
		if(!FindLoggedMovementHitEntry(NewMovementHit.TraceTag, LoggedMovementHit))
			return;

		bool bHitResultChanged = false;
		if(!NewMovementHit.Location.Equals(LoggedMovementHit.OriginalHitResult.Location))
			bHitResultChanged = true;
		else if(!NewMovementHit.ImpactPoint.Equals(LoggedMovementHit.OriginalHitResult.ImpactPoint))
			bHitResultChanged = true;
		else if(!NewMovementHit.Normal.Equals(LoggedMovementHit.OriginalHitResult.Normal))
			bHitResultChanged = true;
		else if(!NewMovementHit.ImpactNormal.Equals(LoggedMovementHit.OriginalHitResult.ImpactNormal))
			bHitResultChanged = true;

		if(!LoggedMovementHit.bOverwritten && bHitResultChanged)
		{
			// When overwriting, always store the original for reference (and debugging the actual hit result)
			LoggedMovementHit.SectionLog.HitResults(
				f"Original_{LoggedMovementHit.TraceTag.ToString()}",
				LoggedMovementHit.OriginalHitResult,
				LoggedMovementHit.TraceShape,
				LoggedMovementHit.CollisionShapeOffset
			);

			MarkMovementHitEntryOverwritten(NewMovementHit.TraceTag);
		}

		LogMovementHit(
			LoggedMovementHit.SectionLog,
			NewMovementHit,
			LoggedMovementHit.TraceShape,
			LoggedMovementHit.CollisionShapeOffset
		);
	}

	void OverlapResults(
		FHazeTraceTag InTraceTag,
		FOverlapResultArray Overlaps,
	)
	{
		if(!CanLog())
			return;

		PreValueLogged();

		const FTemporalLog OverlapResultsLog = GetSectionLog();
		OverlapResultsLog.OverlapResults(
			InTraceTag.ToString(),
			Overlaps, 
			Resolver.IterationTraceSettings.CollisionShapeOffset
		);

		NumOverlaps++;
	}

	void Shape(
		FString InName,
		FVector InOrigin,
		FHazeTraceShape InShape,
		FVector InShapeWorldOffset,
		FLinearColor InColor = FLinearColor::Red,
		float LineWeight = 1.0,
	)
	{
		if(!CanLog())
			return;

		PreValueLogged();
		GetSectionLog().Shape(InName, InOrigin + InShapeWorldOffset, InShape.Shape, InShape.Orientation.Rotator(), InColor, LineWeight);
	}

	void Shape(
		FString InName,
		FVector InOrigin,
		FCollisionShape InShape,
		FRotator InRotation = FRotator::ZeroRotator,
		FLinearColor InColor = FLinearColor::Red,
		float LineWeight = 1.0,
	)
	{
		if(!CanLog())
			return;

		PreValueLogged();
		GetSectionLog().Shape(InName, InOrigin, InShape, InRotation, InColor, LineWeight);
	}

	void MovementShape(
		FString InName,
		FVector InOrigin,
		FHazeMovementTraceSettings InTraceSettings,
		FLinearColor InColor = FLinearColor::Red,
		float LineWeight = 1.0,
	)
	{
		if(!CanLog())
			return;

		PreValueLogged();
		GetSectionLog().MovementShape(InName, InOrigin, InTraceSettings, InColor, LineWeight);
	}

	void Sphere(
		FString InName,
		FVector InOrigin,
		float InRadius,
		FLinearColor InColor = FLinearColor::Red,
		float InLineWeight = 1.0,
	)
	{
		if(!CanLog())
			return;

		PreValueLogged();
		GetSectionLog().Sphere(InName, InOrigin, InRadius, InColor, InLineWeight);
	}

	void MovementDelta(FString InName, FVector InOrigin, FMovementDelta InMovementDelta, float InSize = 2, float InArrowSize = 10, FLinearColor InColor = FLinearColor::Red)
	{
		if(!CanLog())
			return;

		PreValueLogged();
		GetSectionLog(InName)
			.DirectionalArrow("Delta", InOrigin, InMovementDelta.Delta, InSize, InArrowSize, InColor)
			.DirectionalArrow("Velocity", InOrigin, InMovementDelta.Velocity, InSize, InArrowSize, InColor)
		;
	}

	void Point(FString InName, FVector InPoint, float InSize = 10, FLinearColor InColor = FLinearColor::Red)
	{
		if(!CanLog())
			return;

		PreValueLogged();
		GetSectionLog().Point(InName, InPoint, InSize, InColor);
	}

	void Arrow(FString InName, FVector InOrigin, FVector InTarget, float InSize = 2, float InArrowSize = 20, FLinearColor InColor = FLinearColor::Red)
	{
		if(!CanLog())
			return;

		PreValueLogged();
		GetSectionLog().Arrow(InName, InOrigin, InTarget, InSize, InArrowSize, InColor);
	}

	void DirectionalArrow(FString InName, FVector InOrigin, FVector InDelta, float InSize = 2, float InArrowSize = 20, FLinearColor InColor = FLinearColor::Red)
	{
		if(!CanLog())
			return;

		PreValueLogged();
		GetSectionLog().DirectionalArrow(InName, InOrigin, InDelta, InSize, InArrowSize, InColor);
	}

	void Plane(FString InName, FVector InOrigin, FVector InNormal, float InSize = 500, int MaxNumSquares = 16, float Thickness = 3, FLinearColor InColor = FLinearColor::White)
	{
		if(!CanLog())
			return;

		PreValueLogged();
		GetSectionLog().Plane(InName, InOrigin, InNormal, InSize, MaxNumSquares, Thickness, InColor);
	}

	void Circle(FString InName, FVector InOrigin, FVector InNormal, float InRadius = 500, float Thickness = 3, FLinearColor InColor = FLinearColor::White)
	{
		if(!CanLog())
			return;

		PreValueLogged();
		GetSectionLog().Circle(InName, InOrigin, InRadius, FRotator::MakeFromZ(InNormal), InColor, Thickness);
	}
};

/**
 * Set the movement temporal log context while this struct is in scope, and clear when it goes out of scope.
 * When overriding base functions, add a scope with the same name as the function after calling Super::, and they should be grouped in the temporal log.
 */
struct FMovementResolverTemporalLogContextScope
{
	UMovementResolverTemporalLog ResolverTemporalLog;
	FName ContextName;

	FMovementResolverTemporalLogContextScope(const UBaseMovementResolver InResolver, FName InContextName)
	{
		if(!ensure(InResolver != nullptr))
			return;

		if(!ensure(InContextName != NAME_None))
			return;

		ResolverTemporalLog = InResolver.ResolverTemporalLog;
		ContextName = InContextName;

		ResolverTemporalLog.PushContext(InContextName);
	}

	~FMovementResolverTemporalLogContextScope()
	{
		if(ResolverTemporalLog == nullptr)
			return;

		if(ContextName == NAME_None)
			return;

		ResolverTemporalLog.PopContext(ContextName);
	}
};

/**
 * The current context we are logging in.
 * Usually refers to the current function.
 */
struct FMovementResolverTemporalLogContext
{
	FName Name;
	int ContextID;
	int LoggedInContextCount;
	int Instigators = 1;

	FMovementResolverTemporalLogContext(FName InContextName, int InContextID)
	{
		Name = InContextName;
		ContextID = InContextID;
		LoggedInContextCount = 0;
		Instigators = 1;
	}
};

struct FMovementResolverTemporalLogLoggedMovementHitEntry
{
	FTemporalLog SectionLog;
	FHazeTraceTag TraceTag;
	FHazeTraceShape TraceShape;
	FVector CollisionShapeOffset;
	FHitResult OriginalHitResult;
	bool bOverwritten = false;

	FMovementResolverTemporalLogLoggedMovementHitEntry(
		FTemporalLog InSectionLog,
		FHazeTraceTag InTraceTag,
		FHazeTraceShape InTraceShape,
		FVector InCollisionShapeOffset,
		FHitResult InOriginalHitResult,
	)
	{
		SectionLog = InSectionLog;
		TraceTag = InTraceTag;
		TraceShape = InTraceShape;
		CollisionShapeOffset = InCollisionShapeOffset;
		OriginalHitResult = InOriginalHitResult;
	}
};
#endif

/**
 * Log a FMovementHitResult created while tracing in a movement resolver.
 */
mixin FTemporalLog MovementHit(
	FTemporalLog TemporalLog,
	FString Name, 
	FMovementHitResult MovementHit,
	FHazeTraceShape TraceShape,
	FVector CollisionShapeOffset) allow_discard
{
	TemporalLog.HitResults(
		Name,
		MovementHit.ConvertToHitResult(), 
		TraceShape,
		CollisionShapeOffset
	);

	if(TraceShape.IsLine())
		return TemporalLog;

	TemporalLog.Value("Type", MovementHit.Type);

	if(MovementHit.IsAnyGroundContact())
	{
		TemporalLog.Value("Is Walkable", MovementHit.bIsWalkable);
		TemporalLog.Value("Is Step Up", MovementHit.bIsStepUp);

		if(MovementHit.bIsStepUp)
			TemporalLog.Value("StepUpHeight", MovementHit.StepUpHeight);

		FTemporalLog EdgeResultLog = TemporalLog.Section("EdgeResult");
		EdgeResultLog.Value("Type", MovementHit.EdgeResult.Type);
		if(MovementHit.EdgeResult.IsEdge())
		{
			EdgeResultLog.DirectionalArrow("GroundNormal", MovementHit.ImpactPoint, MovementHit.EdgeResult.GroundNormal * 50, Color = FLinearColor::Green);
			EdgeResultLog.DirectionalArrow("EdgeNormal", MovementHit.ImpactPoint, MovementHit.EdgeResult.EdgeNormal * 50, Color = FLinearColor::Red);
			EdgeResultLog.DirectionalArrow("OverrideRedirectNormal", MovementHit.ImpactPoint, MovementHit.EdgeResult.OverrideRedirectNormal * 50, Color = FLinearColor::Yellow);
			EdgeResultLog.Value("UnstableDistance", MovementHit.EdgeResult.UnstableDistance);
			EdgeResultLog.Value("Distance", MovementHit.EdgeResult.Distance);
			EdgeResultLog.Value("bIsOnEmptySideOfLedge", MovementHit.EdgeResult.bIsOnEmptySideOfLedge);
			EdgeResultLog.Value("bMovingPastEdge", MovementHit.EdgeResult.bMovingPastEdge);
		}
	}

	return TemporalLog;
}

/**
 * Log a shape used for tracing in the movement system.
 * @param Origin This is the Actor Location, and the CollisionShapeOffset will automatically be added to it.
 */
mixin FTemporalLog MovementShape(
	FTemporalLog TemporalLog,
	FString Name, 
	FVector Origin,
	FHazeMovementTraceSettings TraceSettings,
	FLinearColor Color = FLinearColor::Red,
	float LineWeight = 1.0) allow_discard
{
	TemporalLog.Shape(
		Name,
		Origin + TraceSettings.CollisionShapeOffset,
		TraceSettings.TraceShape.Shape,
		TraceSettings.CollisionShapeWorldRotation.Rotator(),
		Color,
		LineWeight
	);

	return TemporalLog;
}