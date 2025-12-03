class UJetskiMovementResolver : UFloatingMovementResolver
{
	default RequiredDataType = UJetskiMovementData;
	private const UJetskiMovementData MoveData;

	private bool bDeathFromImpact = false;
	private FHitResult DeathImpact;
	private FVector DeathVelocity;

	private bool bPoleRedirected = false;
	private FVector PoleRedirectImpulse;

	private bool bReflectedOffWall = false;
	private FVector ReflectionImpulse;
	private FQuat ReflectionDeltaRotation;

	void PrepareResolver(const UBaseMovementData Movement) override
	{
		MoveData = Cast<UJetskiMovementData>(Movement);

		Super::PrepareResolver(Movement);
		
		bDeathFromImpact = false;
		DeathImpact = FHitResult();
		DeathVelocity = FVector::ZeroVector;

		bPoleRedirected = false;
		PoleRedirectImpulse = FVector::ZeroVector;
		
		bReflectedOffWall = false;
		ReflectionImpulse = FVector::ZeroVector;
		ReflectionDeltaRotation = FQuat::Identity;
	}

	bool PrepareNextIteration() override
	{
		if(!Super::PrepareNextIteration())
			return false;

		/**
		 * All of the clamping stuff is only for when we are on a spline
		 * We would then clamp the movement so that it doesn't go outside the width of the spline
		 */
		if(IterationCount == 1 && MoveData.bClamp)
			ClampInitialLocation();
		
		return true;
	}

	bool IsLeavingGround() const override
	{
		// If we are upside down
		if(CurrentWorldUp.DotProduct(FVector::UpVector) < 0)
		{
			const FMovementDelta MovementDelta = IterationState.GetDelta(EMovementIterationDeltaStateType::Movement);

			// And we are falling, leave ground
			const float Dot = MovementDelta.Delta.DotProduct(FVector::UpVector);
			if(Dot < 0)
				return true;
		}

		return Super::IsLeavingGround();
	}

	void HandleIterationDeltaMovementImpact(FMovementHitResult& MovementHit) override
	{
		if(ShouldClampDelta())
			ClampDelta();

		Super::HandleIterationDeltaMovementImpact(MovementHit);
	}

	void HandleIterationDeltaMovementWithoutImpact() override
	{
		if(ShouldClampDelta())
			ClampDelta();

		Super::HandleIterationDeltaMovementWithoutImpact();
	}

	private void ClampInitialLocation()
	{
		const FVector InitialLocationRelativeToSpline = MoveData.SplineTransform.InverseTransformPositionNoScale(IterationState.CurrentLocation);

		const float SplineWidth = Math::Abs(MoveData.SplineTransform.Scale3D.Y);
		const float SideOffset = InitialLocationRelativeToSpline.Y;

		if(Math::Abs(SideOffset) > SplineWidth)
		{
			FVector LocationRelativeToSpline = InitialLocationRelativeToSpline;
			LocationRelativeToSpline.Y = SplineWidth * Math::Sign(LocationRelativeToSpline.Y);
			IterationState.CurrentLocation = MoveData.SplineTransform.TransformPositionNoScale(LocationRelativeToSpline);
		}
	}

	private bool ShouldClampDelta() const
	{
		if(!MoveData.bClamp)
			return false;

		return true;
	}

	private void ClampDelta()
	{
		const FVector InitialTargetLocation = IterationState.CurrentLocation + IterationState.DeltaToTrace;
		const FVector InitialTargetLocationRelativeToSpline = MoveData.SplineTransform.InverseTransformPositionNoScale(InitialTargetLocation);

		const float SplineWidth = MoveData.SplineTransform.Scale3D.Y;
		const float SideOffset = InitialTargetLocationRelativeToSpline.Y;

		if(Math::Abs(SideOffset) > SplineWidth)
		{
			const bool bIsOnLeftSide = SideOffset < 0;
			const bool bIsGoingLeft = IterationState.DeltaToTrace.DotProduct(MoveData.SplineTransform.Rotation.RightVector) < 0;

			if(bIsOnLeftSide == bIsGoingLeft)
			{
				const FVector SideNormal = MoveData.SplineTransform.Rotation.RightVector * (bIsOnLeftSide ? -1 : 1);
				FMovementDelta ProjectedDelta = IterationState.GetDelta(EMovementIterationDeltaStateType::Movement).PlaneProject(SideNormal, true);

				IterationState.DeltaToTrace = ProjectedDelta.Delta;

				FVector TargetLocationRelativeToSpline = MoveData.SplineTransform.InverseTransformPositionNoScale(IterationState.CurrentLocation + ProjectedDelta.Delta);
				if(Math::Abs(TargetLocationRelativeToSpline.Y) > SplineWidth)
				{
					TargetLocationRelativeToSpline.Y = SplineWidth * Math::Sign(TargetLocationRelativeToSpline.Y);
					FVector TargetLocation = MoveData.SplineTransform.TransformPositionNoScale(TargetLocationRelativeToSpline);
					ProjectedDelta.Delta = (TargetLocation - IterationState.CurrentLocation);
				}

				IterationState.OverrideDelta(EMovementIterationDeltaStateType::Movement, ProjectedDelta);
			}
		}
	}

	EMovementResolverHandleMovementImpactResult HandleMovementImpact(
		FMovementHitResult Hit,
		EMovementResolverAnyShapeTraceImpactType ImpactType) override
	{
		if(ImpactType == EMovementResolverAnyShapeTraceImpactType::Iteration)
		{
			bool bDeathFromPole = false;
			if(HitPoleRedirect(IterationState, Hit, bDeathFromPole, PoleRedirectImpulse))
			{
				IterationTraceSettings.AddNextTraceIgnoredActor(Hit.Actor);

				if(bDeathFromPole)
				{
					bDeathFromImpact = true;
					DeathImpact = Hit.ConvertToHitResult();
					DeathVelocity = IterationState.GetDelta().Velocity;
					return EMovementResolverHandleMovementImpactResult::Continue;
				}
				else
				{
					bPoleRedirected = true;
					return EMovementResolverHandleMovementImpactResult::Skip;
				}
			}
		}

		if(CheckDeathFromWallHit(Hit, ImpactType))
		{
			bDeathFromImpact = true;
			DeathImpact = Hit.ConvertToHitResult();
			DeathVelocity = IterationState.GetDelta().Velocity;
			return EMovementResolverHandleMovementImpactResult::Continue;
		}

		if(CheckBounceOffWall(Hit, ImpactType, IterationState, ReflectionImpulse, ReflectionDeltaRotation))
		{
			bReflectedOffWall = true;
			return EMovementResolverHandleMovementImpactResult::Skip;
		}

		return EMovementResolverHandleMovementImpactResult::Continue;
	}

	bool HitPoleRedirect(FMovementResolverState& State, FMovementHitResult Hit, bool&out bOutDeathFromPole, FVector&out OutPoleRedirectImpulse) const
	{
		if(!MoveData.bDriverIsAlive)
			return false;

		if(!Hit.IsValidBlockingHit())
			return false;

		auto PoleRedirect = Cast<AJetskiPoleRedirect>(Hit.Actor);
		if(PoleRedirect == nullptr)
			return false;

		const FPlane PolePlane = FPlane(PoleRedirect.ActorLocation, PoleRedirect.ActorRightVector);
		float PlaneDot = PolePlane.PlaneDot(Hit.Location);
		const bool bIsOnRightSide = PlaneDot > 0;

		if(PoleRedirect.bKillAtCenter)
		{
			if(Math::Abs(PlaneDot) < PoleRedirect.CenterMargin)
			{
				// In center, KILL!!!
				bOutDeathFromPole = true;
				return true;
			}
		}

		switch(PoleRedirect.RedirectDirection)
		{
			case EJetskiPoleRedirectDirection::Both:
				break;

			case EJetskiPoleRedirectDirection::Left:
				if(bIsOnRightSide)
					return false;
				break;

			case EJetskiPoleRedirectDirection::Right:
				if(!bIsOnRightSide)
					return false;
				break;
		}

		float RedirectDistance = Math::Sign(PlaneDot) * (PoleRedirect.BoxExtent.Y + TraceShape.Extent.AbsMax + PoleRedirect.SafetyMargin);
		FPlane TargetPlane = FPlane(PoleRedirect.ActorLocation + (PoleRedirect.ActorRightVector * RedirectDistance), PoleRedirect.ActorRightVector);
		FVector TargetLocation = Hit.Location.PointPlaneProject(TargetPlane.Origin, TargetPlane.Normal);

#if !RELEASE
		if(CanTemporalLog())
		{
			GetTemporalLog().Page("PoleRedirect").Value("PlaneDot", PlaneDot);
			GetTemporalLog().Page("PoleRedirect").Value("RedirectDistance", RedirectDistance);
			GetTemporalLog().Page("PoleRedirect").Plane("TargetPlane", TargetLocation, TargetPlane.Normal);
			GetTemporalLog().Page("PoleRedirect").Sphere("TargetLocation", TargetLocation, TraceShape.Extent.AbsMax);
		}
#endif

		const FVector Delta = TargetLocation - State.CurrentLocation;

		FVector Impulse = Hit.Normal * ((Delta / IterationTime) * 0.2).Size();
		if(!bIsOnRightSide)
			Impulse *= -1;

		OutPoleRedirectImpulse = Impulse;

		// for(auto It : State.DeltaStates)
		// {
		// 	FMovementDelta MovementDelta = It.Value.ConvertToDelta();
		// 	if(MovementDelta.IsNearlyZero())
		// 		continue;

		// 	MovementDelta.Delta = Delta;

		// 	FVector NewVelocityAlongRedirect = (Delta / IterationTime);
		// 	FVector OldVelocityAlongRedirect = MovementDelta.Velocity.ProjectOnToNormal(NewVelocityAlongRedirect.GetSafeNormal());

		// 	MovementDelta.Velocity -= OldVelocityAlongRedirect;
		// 	MovementDelta.Velocity += NewVelocityAlongRedirect;

		// 	State.OverrideDelta(It.Key, MovementDelta);
		// }

		State.CurrentLocation = TargetLocation;

		return true;
	}

	FMovementHitResult QueryGroundShapeTrace(
		FHazeMovementTraceSettings TraceSettings,
		FVector StartLocation,
		FVector GroundTraceDelta,
		FVector WorldUp,
		FMovementResolverGroundTraceSettings GroundTraceSettings = FMovementResolverGroundTraceSettings()) const override
	{
		FMovementHitResult GroundHit = Super::QueryGroundShapeTrace(TraceSettings, StartLocation, GroundTraceDelta, WorldUp, GroundTraceSettings);

		if(!MoveData.bAllowAligningWithCeiling)
		{
			if(FVector::UpVector.GetAngleDegreesTo(GroundHit.Normal) > MoveData.WalkableSlopeAngle)
			{
				GroundHit.bIsWalkable = false;

#if !RELEASE
				ResolverTemporalLog.OverwriteMovementHit(GroundHit);
#endif
			}
		}

		return GroundHit;
	}

	bool CheckDeathFromWallHit(FMovementHitResult Hit, EMovementResolverAnyShapeTraceImpactType ImpactType) const
	{
		if(!MoveData.bDriverIsAlive)
			return false;

		if(!MoveData.bCanDieFromWallImpacts)
			return false;

		if(ImpactType != EMovementResolverAnyShapeTraceImpactType::Iteration)
			return false;

		// Check if it is a wall
		if(!Hit.IsWallImpact())
			return false;

		FVector Velocity = IterationState.GetDelta().Velocity;

		float JetskiHitImpulse = Velocity.DotProduct(-Hit.ImpactNormal);
		float JetskiImpactAngle = Math::DotToDegrees(Hit.Normal.DotProduct(-IterationState.CurrentRotation.ForwardVector));
		
		if(JetskiImpactAngle < MoveData.WallImpactDeathJetskiAngleMax && JetskiHitImpulse > MoveData.MinForwardSpeedToDie)
		{
#if !RELEASE
			if(CanTemporalLog())
				GetTemporalLog().Page("WallImpact").Event("Death from Wall Impact Spline Angle");
#endif

			return true;
		}

		float SplineImpactAngle = Math::DotToDegrees(Hit.Normal.DotProduct(-MoveData.SplineTransform.Rotation.ForwardVector));

		if(SplineImpactAngle < MoveData.WallImpactDeathSplineAngleMax)
		{
#if !RELEASE
			if(CanTemporalLog())
				GetTemporalLog().Page("WallImpact").Event("Death from Wall Impact Spline Angle");
#endif

			return true;
		}

		return false;
	}

	bool CheckBounceOffWall(FMovementHitResult Hit, EMovementResolverAnyShapeTraceImpactType ImpactType, FMovementResolverState& State, FVector&out OutReflectionImpulse, FQuat&out OutReflectionDeltaRotation) const
	{
		if(!MoveData.bDriverIsAlive)
			return false;

		if(ImpactType != EMovementResolverAnyShapeTraceImpactType::Iteration)
			return false;

		if(!Hit.IsWallImpact())
			return false;

		FVector Velocity = State.GetDelta().Velocity;

		FVector HorizontalNormal = Hit.Normal.VectorPlaneProject(CurrentWorldUp).GetSafeNormal();
		OutReflectionImpulse = Velocity.ProjectOnToNormal(-HorizontalNormal);

		// Iterate through all the different "deltas" (velocities) on the current iteration state, and override
		// them with new velocities that are reflected off the wall
		for(auto It : State.DeltaStates)
		{
			FMovementDelta MovementDelta = It.Value.ConvertToDelta();
			if(MovementDelta.IsNearlyZero())
				continue;

			FVector FlatNormal = Hit.Normal.VectorPlaneProject(CurrentWorldUp).GetSafeNormal();
			MovementDelta = MovementDelta.Bounce(FlatNormal, 0.5);

			// Override the delta
			State.OverrideDelta(It.Key, MovementDelta);
		}

		FQuat NewRotation = FQuat::MakeFromZX(State.CurrentRotation.UpVector, State.GetDelta().Velocity);
		OutReflectionDeltaRotation = NewRotation * State.CurrentRotation.Inverse();
		State.CurrentRotation = NewRotation;

		return true;
	}

	void ApplyResolvedData(UHazeMovementComponent MovementComponent) override
	{
		auto Jetski = Cast<AJetski>(MovementComponent.Owner);

		if(bPoleRedirected)
			Jetski.ApplyPoleRedirect(PoleRedirectImpulse);

		Super::ApplyResolvedData(MovementComponent);

		if(bDeathFromImpact)
			Jetski.ApplyDeathFromImpact(Time::FrameNumber, DeathImpact, DeathVelocity);

		if(bReflectedOffWall)
			Jetski.ApplyReflectedOffWall(ReflectionImpulse, ReflectionDeltaRotation);
	}
}