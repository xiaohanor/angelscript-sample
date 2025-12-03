class UGravityBikeSplineMovementResolver : UFloatingMovementResolver
{
	default RequiredDataType = UGravityBikeSplineMovementData;

	private const UGravityBikeSplineMovementData MoveData;

	private TArray<FGravityBikeSplineImpactResponseComponentAndData> Impacts;

	private bool bAlignedWithWall = false;
	private FVector AlignWithWallImpulse;
	private FQuat AlignWithWallDeltaRotation;

	private bool bDeathFromWallHit = false;
	private FHitResult DeathFromWallHit;

	private bool bIterationStartedGrounded = false;
	private bool bLanded = false;
	private float LandingImpulseIntoGround = -1;
	private FHitResult LandingHit;

	const float RampVerticalVelocityThreshold = 500;
	const float RampAngleDiffThreshold = 1;

	void PrepareResolver(const UBaseMovementData Movement) override
	{
		Super::PrepareResolver(Movement);

		MoveData = Cast<UGravityBikeSplineMovementData>(Movement);

		if(MoveData.bClampYaw)
		{
			// Clamp rotation yaw to always face forward
			FRotator RelativeRotation = MoveData.ClampReference.InverseTransformRotation(IterationState.CurrentRotation).Rotator();
			float ClampedYaw = Math::Clamp(RelativeRotation.Yaw, -MoveData.ClampAngle, MoveData.ClampAngle);
			RelativeRotation = FRotator(RelativeRotation.Pitch, ClampedYaw, RelativeRotation.Roll);
			IterationState.CurrentRotation = MoveData.ClampReference.TransformRotation(RelativeRotation.Quaternion());
		}

		Impacts.Reset();

		bAlignedWithWall = false;
		AlignWithWallImpulse = FVector::ZeroVector;
		AlignWithWallDeltaRotation = FQuat::Identity;

		bDeathFromWallHit = false;
		DeathFromWallHit = FHitResult();

		bIterationStartedGrounded = false;
		bLanded = false;
		LandingImpulseIntoGround = -1;
		LandingHit = FHitResult();
	}

	bool PrepareNextIteration() override
	{
		if(!Super::PrepareNextIteration())
			return false;

		bIterationStartedGrounded = IterationState.PhysicsState.GroundContact.IsAnyWalkableContact();
		return true;
	}

	void PrepareFirstIteration() override
	{
		Super::PrepareFirstIteration();
		
		if(MoveData.AutoAimAlpha > KINDA_SMALL_NUMBER)
			AutoAimInitialLocation();
	}

	private void AutoAimInitialLocation()
	{
		const FVector InitialLocationRelativeToSpline = MoveData.SplineTransform.InverseTransformPositionNoScale(IterationState.CurrentLocation);

		const float SideOffset = InitialLocationRelativeToSpline.Y;
		const float AutoAimTarget = MoveData.SplineTransform.Scale3D.Y * Math::Sign(SideOffset);

		if(Math::Abs(SideOffset) > Math::Abs(AutoAimTarget))
		{
			FVector LocationRelativeToSpline = InitialLocationRelativeToSpline;
			LocationRelativeToSpline.Y = Math::FInterpTo(LocationRelativeToSpline.Y, AutoAimTarget, IterationTime, MoveData.AutoAimData.AutoAimStrength * Math::Pow(MoveData.AutoAimAlpha, GravityBikeSpline::AutoAimExponent));
			IterationState.CurrentLocation = MoveData.SplineTransform.TransformPositionNoScale(LocationRelativeToSpline);
		}
	}

	float GetGroundTraceDistance() const override
	{
		return Super::GetGroundTraceDistance() + 1; // Slightly more ground tracing to stick to the ground
	}

	bool TryAlignWorldUpWithImpact(FMovementHitResult& Impact) override
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"TryAlignWorldUpWithImpact");
#endif

		if(IsGroundRampEdge(Impact))
			return false;

		return Super::TryAlignWorldUpWithImpact(Impact);
	}

	bool IsGroundRampEdge(FMovementHitResult Impact) const
	{
		// If we are aligning with ground...
		if(Impact.IsAnyGroundContact())
		{
			// .. and we are moving up vertically...
			const FVector Velocity = IterationState.GetDelta().Velocity;
			const float VerticalVelocity = Velocity.DotProduct(MoveData.GlobalWorldUp);
			if(VerticalVelocity > RampVerticalVelocityThreshold)
			{
				const FVector CurrentNormal = IterationState.PhysicsState.GroundContact.IsValidBlockingHit() ? IterationState.PhysicsState.GroundContact.Normal : CurrentWorldUp;
				const FVector ProposedNormal = Impact.ImpactNormal;

				const float CurrentAngle = CurrentNormal.GetAngleDegreesTo(MoveData.GlobalWorldUp);
				float ProposedAngle = ProposedNormal.GetAngleDegreesTo(MoveData.GlobalWorldUp);

				const FVector CurrentNormalOnWorldUpPlane = CurrentNormal.VectorPlaneProject(MoveData.GlobalWorldUp);
				const FVector ProposedNormalOnWorldUpPlane = ProposedNormal.VectorPlaneProject(MoveData.GlobalWorldUp);

				if(CurrentNormalOnWorldUpPlane.DotProduct(ProposedNormalOnWorldUpPlane) < 0)
				{
					// If the proposed normal is pointing away from the current normal along the world up plane, we must flip the proposed angle value
					ProposedAngle *= -1;
				}

				// .. and the new ground is flatter than our current world up...
				if(ProposedAngle < CurrentAngle - RampAngleDiffThreshold)
				{
#if !RELEASE
					ResolverTemporalLog.Value("IsGroundRampEdge", true);
#endif
					// We are moving up a ramp
					return true;
				}
			}
		}

#if !RELEASE
		ResolverTemporalLog.Value("IsGroundRampEdge", false);
#endif

		return false;
	}

	bool IsLeavingEdge(FMovementHitResult HitResult) const override
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"IsLeavingEdge");
#endif

		if(IsGroundRampEdge(HitResult))
			return true;

		return Super::IsLeavingEdge(HitResult);
	}

	void ApplyImpactOnDeltas(FMovementHitResult Impact) override
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"ApplyImpactOnDeltas");
#endif

		if(IsGroundRampEdge(Impact))
			return;

		Super::ApplyImpactOnDeltas(Impact);
	}

	FMovementHitResult QueryGroundShapeTrace(
		FHazeMovementTraceSettings TraceSettings,
		FVector StartLocation,
		FVector GroundTraceDelta,
		FVector WorldUp,
		FMovementResolverGroundTraceSettings GroundTraceSettings = FMovementResolverGroundTraceSettings()) const override
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"QueryGroundShapeTrace");
#endif

		FMovementHitResult GroundHit = Super::QueryGroundShapeTrace(
			TraceSettings,
			StartLocation,
			GroundTraceDelta,
			WorldUp,
			GroundTraceSettings
		);

		if(IsGroundRampEdge(GroundHit))
			GroundHit = FMovementHitResult();

		return GroundHit;
	}

	EMovementResolverHandleMovementImpactResult HandleMovementImpact(FMovementHitResult Hit, EMovementResolverAnyShapeTraceImpactType ImpactType) override
	{
		if(!bLanded && IsLandingImpact(Hit, ImpactType))
		{
			bLanded = true;
			LandingImpulseIntoGround = Math::Abs(IterationState.GetDelta().Velocity.DotProduct(Hit.ImpactNormal));
			LandingHit = Hit.ConvertToHitResult();
		}

		FGravityBikeSplineImpactResponseComponentAndData ResponseCompAndData;
		if(CollisionWithResponseComp(Hit, ResponseCompAndData))
		{
			Impacts.Add(ResponseCompAndData);

			if(ResponseCompAndData.ResponseComp.bIgnoreAfterImpact)
			{
				IterationTraceSettings.AddPermanentIgnoredActor(ResponseCompAndData.ResponseComp.Owner);
				return EMovementResolverHandleMovementImpactResult::Skip;
			}
		}

		if(CheckAlignWithWall(Hit, ImpactType, IterationState, AlignWithWallImpulse, AlignWithWallDeltaRotation))
		{
			bAlignedWithWall = true;
			IterationState.PhysicsState.WallContact = Hit;
			return EMovementResolverHandleMovementImpactResult::Skip;
		}

		if(CheckDeathFromWallHit(Hit, ImpactType))
		{
			bDeathFromWallHit = true;
			DeathFromWallHit = Hit.ConvertToHitResult();
			return EMovementResolverHandleMovementImpactResult::Finish;
		}

		return EMovementResolverHandleMovementImpactResult::Continue;
	}

	bool IsLandingImpact(FMovementHitResult Impact, EMovementResolverAnyShapeTraceImpactType ImpactType) const
	{
		if(MoveData.bAlwaysApplyLandingImpact)
			return true;

		// We are already on the ground
		// We can't use PhysicsState since that is cleared before ground checks
		if(bIterationStartedGrounded)
			return false;

		switch(ImpactType)
		{
			case EMovementResolverAnyShapeTraceImpactType::Iteration:
			case EMovementResolverAnyShapeTraceImpactType::Ground:
			case EMovementResolverAnyShapeTraceImpactType::GroundAtWall:
				break;

			case EMovementResolverAnyShapeTraceImpactType::MoveIntoPlayer:
				return false;
		}

		if(!Impact.IsWalkableGroundContact())
			return false;

		if(!ShouldProjectMovementOnImpact(Impact))
			return false;

		if(IsLeavingGround())
			return false;

		return true;
	}

	bool CollisionWithResponseComp(FMovementHitResult Hit, FGravityBikeSplineImpactResponseComponentAndData&out OutResponseCompAndData) const
	{
		auto ResponseComp = UGravityBikeSplineImpactResponseComponent::Get(Hit.Actor);
		if(ResponseComp == nullptr)
			return false;

		OutResponseCompAndData.ResponseComp = ResponseComp;

		const FHitResult HitResult = Hit.ConvertToHitResult();
		const FVector ImpactVelocity = IterationState.DeltaToTrace / IterationTime;
		OutResponseCompAndData.ImpactData = FGravityBikeSplineOnImpactData(ImpactVelocity, HitResult);

		return true;
	}

	bool CheckAlignWithWall(FMovementHitResult Hit, EMovementResolverAnyShapeTraceImpactType ImpactType, FMovementResolverState& State, FVector&out OutAlignWithWallImpulse, FQuat&out OutAlignWithWallDeltaRotation) const
	{
		if(ImpactType != EMovementResolverAnyShapeTraceImpactType::Iteration)
			return false;

		if(!Hit.IsWallImpact())
			return false;

		if(bAlignedWithWall)
			return false;

		FVector HorizontalNormal = Hit.Normal.VectorPlaneProject(CurrentWorldUp).GetSafeNormal();

		// Does the impact angle allow aligning?
		FVector IntoWallNormal = -HorizontalNormal;
		const float Angle = IntoWallNormal.GetAngleDegreesTo(State.DeltaToTrace.VectorPlaneProject(CurrentWorldUp).GetSafeNormal());
		if(Angle < MoveData.WallAlignMinAngleThreshold)
			return false;

		FVector Velocity = State.GetDelta().Velocity;

		// Iterate through all the different "deltas" (velocities) on the current iteration state, and override
		// them with new velocities that are projected to align with the wall
		for(auto It : State.DeltaStates)
		{
			FMovementDelta MovementDelta = It.Value.ConvertToDelta();
			if(MovementDelta.IsNearlyZero())
				continue;

			MovementDelta = MovementDelta.PlaneProject(HorizontalNormal, true);

			// Override the delta
			State.OverrideDelta(It.Key, MovementDelta);
		}

		OutAlignWithWallImpulse = Velocity.ProjectOnToNormal(-HorizontalNormal);

		FQuat NewRotation = FQuat::MakeFromZX(State.CurrentRotation.UpVector, State.GetDelta(EMovementIterationDeltaStateType::Sum).Velocity);
		OutAlignWithWallDeltaRotation = NewRotation * State.CurrentRotation.Inverse();
		State.CurrentRotation = NewRotation;

		State.CurrentLocation = Hit.Location - Hit.Normal;

		return true;
	}

	bool CheckDeathFromWallHit(FMovementHitResult Hit, EMovementResolverAnyShapeTraceImpactType ImpactType) const
	{
		// Check if it is a wall
		if(!Hit.IsWallImpact())
			return false;

		FVector Velocity = IterationState.GetDelta().Velocity;
		if(Velocity.IsNearlyZero())
			return false;

		if(Hit.Actor.IsA(AGravityBikeSplineEnemy))
		{
			// Never die from hitting an enemy, feels cheap
			return false;
		}

		const FVector SplineDirection = MoveData.SplineForward;

		const float SplineImpactAngle = Hit.Normal.GetAngleDegreesTo(-SplineDirection);

		// We are sliding along this wall, don't die
		if(SplineImpactAngle > MoveData.WallSlideAngleMin)
			return false;

		// This wall is pointing towards the spline, 
		if(SplineImpactAngle < MoveData.WallImpactDeathSplineAngleMax)
			return true;

		const float BikeImpactAngle = Math::DotToDegrees(Hit.Normal.DotProduct(-IterationState.CurrentRotation.ForwardVector));
		if(BikeImpactAngle < MoveData.WallImpactDeathBikeAngleMax)
			return true;

		return false;
	}

	protected EMovementImpactType GetImpactTypeFromHit(FHitResult HitResult, FVector WorldUp, FVector CustomImpactNormal = FVector::ZeroVector) const override
	{
		// Use GlobalWorldUp to stop aligning with ground when we go too far away from the actual world up
		return Super::GetImpactTypeFromHit(HitResult, MoveData.GlobalWorldUp, CustomImpactNormal);
	}

	void ApplyResolvedData(UHazeMovementComponent MovementComponent) override
	{
		Super::ApplyResolvedData(MovementComponent);
		
		auto GravityBike = Cast<AGravityBikeSpline>(MovementComponent.Owner);

		if(GravityBike.HasControl())
		{
			if(bLanded)
				GravityBike.OnLanding(LandingImpulseIntoGround, LandingHit);

			if(!Impacts.IsEmpty())
				GravityBike.BroadcastMovementImpacts(Impacts);

			if(bAlignedWithWall)
				GravityBike.ApplyAlignWithWall(AlignWithWallImpulse, AlignWithWallDeltaRotation);

			if(bDeathFromWallHit)
				GravityBike.ApplyDeathFromWall(Time::FrameNumber, DeathFromWallHit);
		}
	}
}