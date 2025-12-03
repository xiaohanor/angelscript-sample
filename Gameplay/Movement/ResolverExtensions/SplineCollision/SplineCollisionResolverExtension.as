class USplineCollisionResolverExtension : UMovementResolverExtension
{
	default SupportedResolverClasses.Add(USimpleMovementResolver);
	default SupportedResolverClasses.Add(USteppingMovementResolver);
	default SupportedResolverClasses.Add(USweepingMovementResolver);
	default SupportedResolverClasses.Add(UTeleportingMovementResolver);

	UBaseMovementResolver Resolver;
	
	float SafetyDistance = 1.0;
	float Radius = 300.0;
	ASplineActor ClosestSpline;
	FVector WorldUp;

#if EDITOR
	void CopyFrom(const UMovementResolverExtension OtherBase) override
	{
		Super::CopyFrom(OtherBase);
		auto Other = Cast<USplineCollisionResolverExtension>(OtherBase);
		Resolver = Other.Resolver;
		Radius = Other.Radius;
		ClosestSpline = Other.ClosestSpline;
		WorldUp = Other.WorldUp;
	}
#endif

	void PrepareExtension(UBaseMovementResolver InResolver, const UBaseMovementData InMoveData) override
	{
		Super::PrepareExtension(InResolver, InMoveData);

		Resolver = InResolver;
		
		SafetyDistance = InMoveData.SafetyDistance.X;
		Radius = Math::Max(InResolver.TraceShape.Extent.X, InResolver.TraceShape.Extent.Y);

		auto SplineCollisionComp = USplineCollisionComponent::Get(InResolver.Owner);
		ClosestSpline = SplineCollisionComp.GetClosestSpline(GetShapeLocation());

		switch(SplineCollisionComp.WorldUp.Get())
		{
			case ESplineCollisionWorldUp::MovementWorldUp:
				WorldUp = InMoveData.WorldUp;
				break;

			case ESplineCollisionWorldUp::GlobalUp:
				WorldUp = FVector::UpVector;
				break;

			case ESplineCollisionWorldUp::SplineUp:
				WorldUp = ClosestSpline.Spline.GetClosestSplineWorldRotationToWorldLocation(GetShapeLocation()).UpVector;
				break;
		}
	}

	void PostPrepareNextIteration(bool bFirstIteration) override
	{
#if EDITOR
		if(bIsEditorRerunExtension && bFirstIteration)
		{
			check(ClosestSpline.Spline.Mobility != EComponentMobility::Movable || UTemporalLogTransformLoggerComponent::Get(ClosestSpline) != nullptr,
				"For reruns to be possible with USplineCollisionResolverExtension, the splines must be stationary or have a UTemporalLogTransformLoggerComponent!");
		}
#endif

#if !RELEASE
		Resolver.ResolverTemporalLog.MovementShape("PreIterationLocation", Resolver.IterationState.CurrentLocation, Resolver.IterationTraceSettings, FLinearColor::Red);
#endif

		if(ClosestSpline == nullptr)
			return;

		// Make sure that no iteration starts within the spline radius
		const bool bAppliedConstraint = ApplySplineConstraint(Resolver.IterationState, true);

#if !RELEASE
		if(bAppliedConstraint)
		{
			Resolver.ResolverTemporalLog.Value("bAppliedConstraint", true);
			Resolver.ResolverTemporalLog.MovementShape("PostIterationLocation", Resolver.IterationState.CurrentLocation, Resolver.IterationTraceSettings, FLinearColor::Green);
		}
		else
		{
			Resolver.ResolverTemporalLog.Value("bAppliedConstraint", false);
		}
#endif
	}

	void PreApplyResolvedData(UHazeMovementComponent MovementComponent) override
	{
#if !RELEASE
		Resolver.ResolverTemporalLog.MovementShape("PreIterationLocation", Resolver.IterationState.CurrentLocation, Resolver.IterationTraceSettings, FLinearColor::Red);
#endif

		// Once again, we constrain to absolutely ensure we are outside the spline
		bool bAppliedConstraint = ApplySplineConstraint(Resolver.IterationState, false);

#if !RELEASE
		if(bAppliedConstraint)
		{
			Resolver.ResolverTemporalLog.Value("bAppliedConstraint", true);
			Resolver.ResolverTemporalLog.MovementShape("PostIterationLocation", Resolver.IterationState.CurrentLocation, Resolver.IterationTraceSettings, FLinearColor::Green);
		}
		else
		{
			Resolver.ResolverTemporalLog.Value("bAppliedConstraint", false);
		}
#endif

		Super::PreApplyResolvedData(MovementComponent);
	}

	bool ApplySplineConstraint(FMovementResolverState& State, bool bProjectDeltaOntoSplinePlane)
	{
		FVector ShapeLocation = GetShapeLocation();
		FTransform ClosestSplineTransform = GetClosestSplineTransform(ShapeLocation);

#if !RELEASE
		Resolver.ResolverTemporalLog.Sphere("Shape", ShapeLocation, Radius);
		Resolver.ResolverTemporalLog.Point("Closest Point", ClosestSplineTransform.Location);
		Resolver.ResolverTemporalLog.DirectionalArrow("Closest Normal", ClosestSplineTransform.Location, ClosestSplineTransform.Rotation.RightVector * 100, InColor = FLinearColor::Green);
		Resolver.ResolverTemporalLog.Plane("Closest Plane",  ClosestSplineTransform.Location, ClosestSplineTransform.Rotation.RightVector, InColor = FLinearColor::Green);
#endif

		// Check culling conditions at the current shape location
		if(IsCulled(ShapeLocation, ClosestSplineTransform))
			return false;

		// Adjust the spline transform so that the normal points towards the shape,
		// and the location is on the same horizontal plane 
		RadiusAdjustSplineTransform(
			ClosestSplineTransform,
			ShapeLocation
		);

#if !RELEASE
		Resolver.ResolverTemporalLog.Point("Adjusted Point", ClosestSplineTransform.Location);
		Resolver.ResolverTemporalLog.DirectionalArrow("Adjusted Normal", ClosestSplineTransform.Location, ClosestSplineTransform.Rotation.RightVector * 100, InColor = FLinearColor::Red);
		Resolver.ResolverTemporalLog.Plane("Adjusted Plane",  ClosestSplineTransform.Location, ClosestSplineTransform.Rotation.RightVector, InColor = FLinearColor::Red);
#endif

		// Create a plane from the spline transform
		const FPlane SplinePlane = FPlane(ClosestSplineTransform.Location, ClosestSplineTransform.Rotation.RightVector);

		// Depenetrate out of spline
		DepenetrateToOutsideSplinePlane(ShapeLocation, SplinePlane);

		const FVector Start = ShapeLocation;
		const FVector Delta = Resolver.IterationState.DeltaToTrace;
		const FVector End = Start + Delta;

#if !RELEASE
		Resolver.ResolverTemporalLog.MovementShape("Wanted Location", End, Resolver.IterationTraceSettings, FLinearColor::Yellow);
#endif

		// Figure out if we are trying to move through the spline plane this frame
		float32 Time = 0;
		FVector Intersection;
		Math::LinePlaneIntersection(Start, End, SplinePlane, Time, Intersection);

		// We have yet to hit the spline plane
		if(Time > 1.0)
		{
			return false;
		}
		else if(Time < 0.0)
		{
			// We have passed the intersection!
			// Move us back to where it should have been
			Intersection = Start + Delta * Time;
		}

		// We were trying to move thorugh it, stop at the intersection
		ShapeLocation = Intersection + (SplinePlane.Normal * SafetyDistance);

		// Recalculate the spline plane at the intersection

		if(!ValidateNewShapeLocation(ShapeLocation))
			return false;

		// Apply the spline location on the current location
		State.CurrentLocation = Resolver.IterationState.ConvertShapeCenterLocationToCurrentLocation(ShapeLocation, Resolver.IterationTraceSettings);

		if(bProjectDeltaOntoSplinePlane)
		{
			// Ensure that no deltas go through the spline plane
			ProjectDeltaOntoSplinePlane(State, SplinePlane);
		}

		return true;
	}

	bool DepenetrateToOutsideSplinePlane(FVector& ShapeLocation, FPlane SplinePlane) const
	{
		const float PenetrationDepth = Math::Max(-SplinePlane.PlaneDot(ShapeLocation), 0);

		if(PenetrationDepth < SafetyDistance)
		{
			// We are not actually penetrating, no need to adjust
			return false;
		}

		// Depenetrate out of the spline plane
		ShapeLocation = ShapeLocation += SplinePlane.Normal * PenetrationDepth;
		return true;
	}

	void ProjectDeltaOntoSplinePlane(FMovementResolverState& State, FPlane SplinePlane) const
	{
		if(State.DeltaToTrace.DotProduct(SplinePlane.Normal) < 0)
			State.DeltaToTrace = State.DeltaToTrace.VectorPlaneProject(SplinePlane.Normal);
	}

	bool ValidateNewShapeLocation(FVector& ShapeLocation)
	{
		FVector Location = ShapeLocation - Resolver.IterationTraceSettings.CollisionShapeOffset;
		FVector Delta = Location - Resolver.IterationState.CurrentLocation;

		if(Delta.IsNearlyZero())
			return true;

		FMovementHitResult HitResult = Resolver.QueryShapeTrace(Resolver.IterationState.CurrentLocation, Delta, Resolver.GenerateTraceTag(n"ValidateNewShapeLocation", n"SplineCollisionResolverExtension"));

#if !RELEASE
		Resolver.ResolverTemporalLog.MovementHit(HitResult, Resolver.IterationTraceSettings.TraceShape, Resolver.IterationTraceSettings.CollisionShapeOffset);
#endif

		if(HitResult.bStartPenetrating)
		{
			return false;
		}
		else if(HitResult.IsValidBlockingHit())
		{
			ShapeLocation = Resolver.IterationState.ConvertLocationToShapeCenterLocation(HitResult.Location, Resolver.IterationTraceSettings);
			return true;
		}
		else
		{
			return true;
		}
	}

	/**
	 * We perform the constraining with the shape location, not the current location
	 */
	FVector GetShapeLocation() const
	{
		return Resolver.IterationState.GetShapeCenterLocation(Resolver.IterationTraceSettings);
	}

	FTransform GetClosestSplineTransform(FVector ShapeLocation) const
	{
		const FSplinePosition ClosestSplinePosition = ClosestSpline.Spline.GetPlaneConstrainedClosestSplinePositionToWorldLocation(ShapeLocation, WorldUp);
		FTransform ClosestSplineTransform = ClosestSplinePosition.WorldTransform;

		// Put the spline transform at the same height as the shape, in the world up direction
		ClosestSplineTransform.SetLocation(ClosestSplineTransform.Location.PointPlaneProject(ShapeLocation, WorldUp));

		return ClosestSplineTransform;
	}

	/**
	 * Optimize by culling cases where we don't need to constrain
	 */
	bool IsCulled(FVector ShapeLocation, FTransform ClosestSplineTransform) const
	{
		// We must take the current delta into account when culling,
		// because at high movement speeds we don't want to be able to penetrate the spline wall
		const FVector FullDelta = Resolver.GenerateIterationDelta().Delta;
		const float CullRadius = Radius + FullDelta.Size();

		if(ClosestSplineTransform.Location.Dist2D(ShapeLocation, WorldUp) > CullRadius)
		{
			// Too far away, no need to constrain
			return true;
		}

		if(FullDelta.DotProduct(ClosestSplineTransform.Location - ShapeLocation) < 0)
		{
			// We are moving away from the spline
			return true;
		}

		return false;
	}

	/**
	 * Rotates the spline transform so that:
	 * Location is the spline location, offset towards the ShapeLocation with the radius.
	 */
	void RadiusAdjustSplineTransform(FTransform& Transform, FVector ShapeLocation) const
	{
		FVector Location = Transform.Location;
		FVector Normal = ShapeLocation - Location;
		Transform.SetRotation(FQuat::MakeFromZY(WorldUp, Normal));
		Transform.SetLocation(Location + Transform.Rotation.RightVector * Radius);
	}

	// bool IsPositionInHole(FSplinePosition Position) const
	// {
	// 	TOptional<FAlongSplineComponentData> FoundHole = BoundarySpline.FindPreviousComponentAlongSpline(URemoteHackableRaftBoundarySplineHoleComponent, Position.CurrentSplineDistance);

	// 	if(FoundHole.IsSet())
	// 	{
	// 		auto HoleComp = Cast<URemoteHackableRaftBoundarySplineHoleComponent>(FoundHole.Value.Component);

	// 		FSplinePosition StartHolePosition = FSplinePosition(BoundarySpline.Spline, FoundHole.Value.DistanceAlongSpline, true);
	// 		FSplinePosition EndSplinePosition = FSplinePosition(BoundarySpline.Spline, FoundHole.Value.DistanceAlongSpline + HoleComp.HoleSize, true);

	// 		if(Position.IsBetweenPositions(StartHolePosition, EndSplinePosition))
	// 			return true;
	// 	}

	// 	return false;
	// }

#if !RELEASE
	void LogFinal(FTemporalLog ExtensionPage, FTemporalLog FinalSectionLog) const override
	{
		Super::LogFinal(ExtensionPage, FinalSectionLog);

		if(ClosestSpline == nullptr)
			return;


		FinalSectionLog.RuntimeSpline("Spline", ClosestSpline.Spline.BuildRuntimeSplineFromHazeSpline(100));
	}
#endif
};