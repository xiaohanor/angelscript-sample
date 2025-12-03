class UCircleConstraintResolverExtension : UMovementResolverExtension
{
	default SupportedResolverClasses.Add(USimpleMovementResolver);
	default SupportedResolverClasses.Add(USteppingMovementResolver);
	default SupportedResolverClasses.Add(USweepingMovementResolver);
	default SupportedResolverClasses.Add(UTeleportingMovementResolver);

	const UCircleConstraintResolverExtensionComponent CircleConstraintComp;

	UBaseMovementResolver Resolver;

	FVector ConstraintOrigin;
	FVector ConstraintNormal;
	float ConstraintRadius = 300.0;
	bool bHardConstraint = false;

#if EDITOR
	void CopyFrom(const UMovementResolverExtension OtherBase) override
	{
		auto Other = Cast<UCircleConstraintResolverExtension>(OtherBase);
		Resolver = Other.Resolver;
		ConstraintOrigin = Other.ConstraintOrigin;
		ConstraintNormal = Other.ConstraintNormal;
		ConstraintRadius = Other.ConstraintRadius;
		bHardConstraint = Other.bHardConstraint;
	}
#endif

	void PrepareExtension(UBaseMovementResolver InResolver, const UBaseMovementData InMoveData) override
	{
		Super::PrepareExtension(InResolver, InMoveData);

		Resolver = InResolver;

		CircleConstraintComp = UCircleConstraintResolverExtensionComponent::Get(InResolver.Owner);
		
		const ACircleConstraintResolverExtensionActor CircleConstraintActor = CircleConstraintComp.CircleConstraintActor.Get();
		ConstraintOrigin = CircleConstraintActor.ActorLocation;
		ConstraintNormal = CircleConstraintActor.ActorUpVector;
		ConstraintRadius = CircleConstraintActor.Radius;
		bHardConstraint = CircleConstraintActor.bHardConstraint;
	}

	bool OnPrepareNextIteration(bool bFirstIteration) override
	{
		for (auto It : Resolver.IterationState.DeltaStates)
		{
			FMovementDelta MovementDelta = It.Value.ConvertToDelta();
			if(MovementDelta.IsNearlyZero())
				continue;

			if(!CalculateWantedDelta(Resolver.IterationState.CurrentLocation, MovementDelta))
				continue;

			Resolver.IterationState.OverrideDelta(It.Key, MovementDelta);
		}

		return true;
	}

	bool CalculateWantedDelta(FVector CurrentLocation, FMovementDelta& MovementDelta)
	{
		const FMovementDelta OriginalVerticalDelta = MovementDelta.GetVerticalPart(ConstraintNormal);

		FVector WantedLocation = CurrentLocation + MovementDelta.Delta;
		FVector DiffFromCircleCenter = WantedLocation - ConstraintOrigin;
		FVector HorizontalDiffFromCircleCenter = DiffFromCircleCenter.VectorPlaneProject(ConstraintNormal);
		const FVector HorizontalConstraintNormal = HorizontalDiffFromCircleCenter.GetSafeNormal();
		FPlane ConstraintPlane(ConstraintOrigin + (HorizontalConstraintNormal * ConstraintRadius), HorizontalConstraintNormal);

		if(ConstraintPlane.PlaneDot(WantedLocation) < 0)
		{
			// We want to go within the constraint radius, so no issues
			return false;
		}

		if(bHardConstraint)
		{
			// The wanted location is outside the constraint radius, clamp it
			FVector ConstrainedHorizontalLocation = ConstraintOrigin + HorizontalDiffFromCircleCenter.GetClampedToMaxSize(ConstraintRadius);
			FVector ConstrainedHorizontalDelta = ConstrainedHorizontalLocation - CurrentLocation.PointPlaneProject(ConstraintOrigin, ConstraintNormal);
			MovementDelta = FMovementDelta(ConstrainedHorizontalDelta + OriginalVerticalDelta.Delta, MovementDelta.Velocity);
			return true;
		}
		else
		{
			float32 Time = 0;
			FVector Intersection = FVector::ZeroVector;
			if(Math::LinePlaneIntersection(CurrentLocation, WantedLocation, ConstraintPlane, Time, Intersection))
			{
				// We have moved through the edge
				// Stop us at the intersection
				WantedLocation = Intersection;

				FMovementDelta DeltaAlongEdgePlane = MovementDelta.PlaneProject(HorizontalConstraintNormal);

				// Multiply the delta going into the edge plane with the time to slow us down the appropriate amount
				FMovementDelta DeltaIntoEdge = MovementDelta.ProjectOntoNormal(HorizontalConstraintNormal);
				DeltaIntoEdge *= Time;

				MovementDelta = DeltaAlongEdgePlane + DeltaIntoEdge;
			}
			else
			{
				// We have already moved past the edge
				// Just constraint us to be along the plane, but not on the plane

				FVector Delta = WantedLocation - CurrentLocation;
				Delta = Delta.VectorPlaneProject(HorizontalConstraintNormal);
				WantedLocation = CurrentLocation + Delta;

				// Clamp any deltas moving into the edge direction
				if(MovementDelta.Delta.DotProduct(HorizontalConstraintNormal) > 0)
					MovementDelta.Delta = MovementDelta.Delta.VectorPlaneProject(HorizontalConstraintNormal);

				if(MovementDelta.Velocity.DotProduct(HorizontalConstraintNormal) > 0)
					MovementDelta.Velocity = MovementDelta.Velocity.VectorPlaneProject(HorizontalConstraintNormal);
			}
		}

		// Keep the original vertical delta
		const FMovementDelta HorizontalMovementDelta = MovementDelta.GetHorizontalPart(ConstraintNormal);
		MovementDelta = HorizontalMovementDelta + OriginalVerticalDelta;
		return true;
	}

#if !RELEASE
	void LogFinal(FTemporalLog ExtensionPage, FTemporalLog FinalSectionLog) const override
	{
		Super::LogFinal(ExtensionPage, FinalSectionLog);

		const ACircleConstraintResolverExtensionActor CircleConstraintActor = CircleConstraintComp.CircleConstraintActor.Get();
		if(CircleConstraintActor == nullptr)
			return;

		FinalSectionLog.Value("CircleConstraintActor", CircleConstraintActor);
		FinalSectionLog.Plane("ConstraintPlane", CircleConstraintActor.ActorLocation, CircleConstraintActor.ActorUpVector);
		FinalSectionLog.Value("Radius", ConstraintRadius);
	}
#endif
};