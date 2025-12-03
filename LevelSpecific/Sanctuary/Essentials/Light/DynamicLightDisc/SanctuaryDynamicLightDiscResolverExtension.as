class USanctuaryDynamicLightDiscResolverExtension : UMovementResolverExtension
{
	default SupportedResolverClasses.Add(USteppingMovementResolver);

	USteppingMovementResolver Resolver;

	bool bDepenetrated = false;

#if !RELEASE
	FVector OriginalLocation;
	FHitResult OriginalHit;
	FHitResult GroundHit;
	FVector FinalLocation;
	FTransform LightDiscTransform;
#endif

#if EDITOR
	void CopyFrom(const UMovementResolverExtension OtherBase) override
	{
		auto Other = Cast<USanctuaryDynamicLightDiscResolverExtension>(OtherBase);
		Resolver = Other.Resolver;
		bDepenetrated = Other.bDepenetrated;
	}
#endif

	void PrepareExtension(UBaseMovementResolver InResolver, const UBaseMovementData InMoveData) override
	{
		Super::PrepareExtension(InResolver, InMoveData);
		
		Resolver = Cast<USteppingMovementResolver>(InResolver);

		bDepenetrated = false;
	}

	bool PreResolveStartPenetrating(FMovementHitResult IterationHit, FVector&out OutResolvedLocation) override
	{
		if(bDepenetrated)
			return false;

		auto LightDiscComp = Cast<USanctuaryDynamicLightDiscComponent>(IterationHit.Component);
		if(LightDiscComp == nullptr)
			return false;
		
		bDepenetrated = true;

		// Find where we want to be placed
		FVector ClosestPointOnDisc = Resolver.IterationState.CurrentLocation.PointPlaneProject(LightDiscComp.WorldLocation, LightDiscComp.UpVector);
		const FVector LocationOnDisc = ClosestPointOnDisc + Resolver.CurrentWorldUp * (Resolver.TraceShape.Extent.Z * 0.5);

		// Trace towards that location
		const FVector GroundTraceDelta = Resolver.CurrentWorldUp * -Resolver.TraceShape.Extent.Z;
		const FHazeTraceTag TraceTag = Resolver.GenerateTraceTag(n"LightDiscGroundTrace", n"PreResolveStartPenetrating");
		FMovementHitResult NewGround = Resolver.QueryShapeTrace(Resolver.IterationTraceSettings, LocationOnDisc, GroundTraceDelta, Resolver.CurrentWorldUp, TraceTag);

#if !RELEASE
		OriginalHit = IterationHit.ConvertToHitResult();
		OriginalLocation = Resolver.IterationState.CurrentLocation;
		GroundHit = NewGround.ConvertToHitResult();
		FinalLocation = NewGround.Location;
		LightDiscTransform = LightDiscComp.WorldTransform;
#endif

		if(NewGround.IsValidBlockingHit() && NewGround.Component == IterationHit.Component)
		{
			// We hit the same light disc that we wanted to be on, place us on it as our new ground
			OutResolvedLocation = NewGround.Location;
			Resolver.ApplyImpactOnDeltas(Resolver.IterationState, NewGround);
			Resolver.ChangeGroundedState(Resolver.IterationState, NewGround);
			return true;
		}
		else
		{
			return false;
		}
	}

#if !RELEASE
	void LogFinal(FTemporalLog ExtensionPage, FTemporalLog FinalSectionLog) const override
	{
		Super::LogFinal(ExtensionPage, FinalSectionLog);

		FinalSectionLog.Value("Depenetrated", bDepenetrated);

		if(bDepenetrated)
		{
			FinalSectionLog.Shape("Original Location", OriginalLocation + Resolver.IterationTraceSettings.CollisionShapeOffset, Resolver.TraceShape.Shape, Resolver.IterationState.CurrentRotation.Rotator());
			FinalSectionLog.Plane("Light Disc Plane", LightDiscTransform.Location, LightDiscTransform.Rotation.UpVector, 2000);
			FinalSectionLog.HitResults("Original Hit", OriginalHit, Resolver.TraceShape, Resolver.IterationTraceSettings.CollisionShapeOffset);
			FinalSectionLog.HitResults("Ground Hit", GroundHit, Resolver.TraceShape, Resolver.IterationTraceSettings.CollisionShapeOffset);
			FinalSectionLog.Shape("Final Location", FinalLocation + Resolver.IterationTraceSettings.CollisionShapeOffset, Resolver.TraceShape.Shape, Resolver.IterationState.CurrentRotation.Rotator());
		}
	}
#endif
};