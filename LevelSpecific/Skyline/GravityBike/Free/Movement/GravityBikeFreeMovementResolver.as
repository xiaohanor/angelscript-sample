class UGravityBikeFreeMovementResolver : UFloatingMovementResolver
{
	default RequiredDataType = UGravityBikeFreeMovementData;

	private const UGravityBikeFreeMovementData MoveData;

	private TArray<FGravityBikeFreeImpactResponseComponentAndData> Impacts;

	private bool bDeathFromWallHit = false;
	private FHitResult DeathFromWallHit;

	private bool bAlignedWithWall = false;
	private FHitResult AlignWithWallHit;
	private FVector AlignWithWallImpulse;
	private FQuat AlignWithWallDeltaRotation;

	private bool bPreviousFrameAlignedWithWall;
	private FVector PreviousFrameAlignWithWallNormal; 

	private bool bIterationStartedGrounded = false;
	private bool bLanded = false;
	private float LandingImpulseIntoGround = -1;
	private FHitResult LandingHit;

	// @see ForceFlatNormals()
	const float RampVerticalVelocityThreshold = 500;
	const float RampAngleDiffThreshold = 1;

	void PrepareResolver(const UBaseMovementData Movement) override
	{
		Super::PrepareResolver(Movement);

		MoveData = Cast<UGravityBikeFreeMovementData>(Movement);

		Impacts.Reset();

		bDeathFromWallHit = false;
		DeathFromWallHit = FHitResult();

		bPreviousFrameAlignedWithWall = bAlignedWithWall;
		PreviousFrameAlignWithWallNormal = AlignWithWallHit.Normal;
		
		bAlignedWithWall = false;
		AlignWithWallHit = FHitResult();
		AlignWithWallImpulse = FVector::ZeroVector;
		AlignWithWallDeltaRotation = FQuat::Identity;

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

	float GetGroundTraceDistance() const override
	{
		return Super::GetGroundTraceDistance() + 1; // Slightly more ground tracing to stick to the ground
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

		if(GroundHit.IsAnyGroundContact())
		{
			float MaximumAllowedAngle = MoveData.WalkableSlopeAngle;
			if(GroundHit.Component.HasTag(ComponentTags::GravityBikeAllowDrivingOnWall))
				MaximumAllowedAngle = 100;
			
			const float AngleToVertical = FVector::UpVector.GetAngleDegreesTo(GroundHit.ImpactNormal);
			if(AngleToVertical > MaximumAllowedAngle)
			{
				// This ground hit should have been a wall!
				GroundHit.Type = EMovementImpactType::Wall;
				return GroundHit;
			}
		}

		if(IsGroundRampEdge(GroundHit))
			return FMovementHitResult();
		
		GroundHit = ForceFlatNormals(GroundHit);
		return GroundHit;
	}

	FMovementDelta ProjectMovementUponImpact(
		FMovementDelta DeltaState,
		FMovementHitResult Impact,
		FMovementHitResult GroundedState) const override
	{
		FMovementHitResult Hit = ForceFlatNormals(Impact);
		return Super::ProjectMovementUponImpact(DeltaState, Hit, GroundedState);
	}

	/**
	 * If the component is has the FlatGroundComponentTag tag, force the normals to be global up
	 * This prevents the gravity bike from redirecting and "jumping" on small bumps
	 * @see FlatGroundComponentTag
	 */
	private FMovementHitResult ForceFlatNormals(FMovementHitResult Hit) const
	{
		if(!Hit.IsValidBlockingHit())
			return Hit;

		if(!Hit.Component.HasTag(ComponentTags::GravityBikeFlatGround))
			return Hit;

		FMovementHitResult FlatHit = Hit;
		FlatHit.OverrideNormals(FVector::UpVector, FVector::UpVector);
		return FlatHit;
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
		if(Impact.IsWalkableGroundContact())
		{
			// .. and we are moving up vertically...
			const FVector Velocity = IterationState.GetDelta().Velocity;
			const float VerticalVelocity = Velocity.DotProduct(FVector::UpVector);
			if(VerticalVelocity > RampVerticalVelocityThreshold)
			{
				const FVector CurrentNormal = IterationState.PhysicsState.GroundContact.IsValidBlockingHit() ? IterationState.PhysicsState.GroundContact.Normal : CurrentWorldUp;
				const FVector ProposedNormal = Impact.ImpactNormal;

				const float CurrentAngle = CurrentNormal.GetAngleDegreesTo(FVector::UpVector);
				float ProposedAngle = ProposedNormal.GetAngleDegreesTo(FVector::UpVector);

				const FVector CurrentNormalOnWorldUpPlane = CurrentNormal.VectorPlaneProject(FVector::UpVector);
				const FVector ProposedNormalOnWorldUpPlane = ProposedNormal.VectorPlaneProject(FVector::UpVector);

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

	void ApplyImpactOnDeltas(FMovementHitResult Impact) override
	{
#if !RELEASE
		FMovementResolverTemporalLogContextScope Scope(this, n"ApplyImpactOnDeltas");
#endif

		if(!Impact.Component.HasTag(ComponentTags::GravityBikeFlatGround))
		{
			// If the impact is not flat ground, and we are leaving an edge, don't apply the impact on the deltas
			if(IsLeavingEdge(Impact))
				return;
		}

		Super::ApplyImpactOnDeltas(Impact);
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

	EMovementResolverHandleMovementImpactResult HandleMovementImpact(FMovementHitResult Hit, EMovementResolverAnyShapeTraceImpactType ImpactType) override
	{
		// if(ReflectOffSteepWall(Hit, IterationState))
		// 	return EMovementResolverHandleMovementImpactResult::Skip;

		if(DeathFromCollisionWithTripodBoss(Hit))
		{
			bDeathFromWallHit = true;
			DeathFromWallHit = Hit.ConvertToHitResult();
			return EMovementResolverHandleMovementImpactResult::Finish;
		}

		if(!bLanded && IsLandingImpact(Hit, ImpactType))
		{
			bLanded = true;
			LandingImpulseIntoGround = Math::Abs(IterationState.GetDelta().Velocity.DotProduct(Hit.ImpactNormal));
			LandingHit = Hit.ConvertToHitResult();
		}

		FGravityBikeFreeImpactResponseComponentAndData ResponseCompAndData;
		if(CollisionWithResponseComp(Hit, ResponseCompAndData))
		{
			Impacts.Add(ResponseCompAndData);
			
			if(ResponseCompAndData.ResponseComp.bIgnoreAfterImpact)
			{
				IterationTraceSettings.AddPermanentIgnoredActor(ResponseCompAndData.ResponseComp.Owner);
				return EMovementResolverHandleMovementImpactResult::Skip;
			}
		}

		if(Hit.IsWallImpact() && ImpactType == EMovementResolverAnyShapeTraceImpactType::Iteration)
		{
			// Handle wall impacts
			const FVector TraceDirection = Hit.TraceDirection.VectorPlaneProject(CurrentWorldUp).GetSafeNormal();
			const FVector HorizontalNormal = Hit.Normal.VectorPlaneProject(CurrentWorldUp).GetSafeNormal();
			const FVector TraceDirectionAlongNormal = TraceDirection.VectorPlaneProject(HorizontalNormal);
			const float ReflectionAngle = TraceDirection.GetAngleDegreesTo(TraceDirectionAlongNormal);

			if(CheckDeathFromWallHit(Hit, ReflectionAngle))
			{
				bDeathFromWallHit = true;
				DeathFromWallHit = Hit.ConvertToHitResult();
				return EMovementResolverHandleMovementImpactResult::Finish;
			}

			if(ShouldAlignWithWall(Hit))
			{
				if(bPreviousFrameAlignedWithWall && PreviousFrameAlignWithWallNormal.GetAngleDegreesTo(Hit.Normal) > 30)
				{
					// We aligned two frames in a row, with very different normals
					// This probably means we are stuck
					// Explode!
					bDeathFromWallHit = true;
					DeathFromWallHit = Hit.ConvertToHitResult();
					return EMovementResolverHandleMovementImpactResult::Finish;
				}

				AlignWithWall(Hit, IterationState, AlignWithWallImpulse, AlignWithWallDeltaRotation);
				bAlignedWithWall = true;
				AlignWithWallHit = Hit.ConvertToHitResult();
				return EMovementResolverHandleMovementImpactResult::Skip;
			}

			// if(CheckReflectOffWall(Hit, ReflectionAngle, IterationState, ReflectionImpulse, ReflectionDeltaRotation))
			// {
			// 	bReflectedOffWall = true;
			// 	return EMovementResolverHandleMovementImpactResult::Skip;
			// }
		}


		return EMovementResolverHandleMovementImpactResult::Continue;
	}

	bool DeathFromCollisionWithTripodBoss(FMovementHitResult Impact) const
	{
		if(!Impact.bBlockingHit)
			return false;

		auto TripodBoss = Cast<ASkylineBoss>(Impact.Actor);
		if(TripodBoss == nullptr)
			return false;

		if(!TripodBoss.IsStateActive(ESkylineBossState::Down))
		{
			// Too late and scary in project to implement this on the entire level
			// This fix was only to prevent the players from landing on the downed boss
			return false;
		}

		// If we hit a primitive component that should kill the player, do so!
		const TArray<UPrimitiveComponent> KillPlayerPrimitives = TripodBoss.BP_GetKillPlayerPrimitives();
		if(KillPlayerPrimitives.Contains(Impact.Component))
			return true;

		if(Impact.Component == TripodBoss.Mesh)
		{
			const FString BoneName = Impact.BoneName.ToString();

			// Ignore leg bones
			if(BoneName.Contains("Leg"))
				return false;

			// Ignore foot bones
			if(BoneName.Contains("Foot"))
				return false;
			
			// We hit a body bone on the tripod boss, die!
			return true;
		}

		return false;
	}

	bool ReflectOffSteepWall(FMovementHitResult Impact, FMovementResolverState& State) const
	{
		if(!Impact.IsAnyGroundContact())
			return false;

		const float AngleToVertical = FVector::UpVector.GetAngleDegreesTo(Impact.Normal);
		if(AngleToVertical < MoveData.WalkableSlopeAngle)
			return false;

		// This should have been a ground impact
		// Push us off!
		for(auto It : State.DeltaStates)
		{
			FMovementDelta MovementDelta = It.Value.ConvertToDelta();
			if(MovementDelta.IsNearlyZero())
				continue;

			MovementDelta = MovementDelta.PlaneProject(Impact.Normal, true);

			// Override the delta
			State.OverrideDelta(It.Key, MovementDelta);
		}

		FVector Impulse = Impact.Normal * 1000;
		Impulse += FVector::UpVector * 500;
		State.OverrideDelta(EMovementIterationDeltaStateType::Impulse, FMovementDelta(Impulse * IterationTime, Impulse));
		return true;
	}

	bool IsLandingImpact(FMovementHitResult Impact, EMovementResolverAnyShapeTraceImpactType ImpactType) const
	{
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

	bool CollisionWithResponseComp(FMovementHitResult Hit, FGravityBikeFreeImpactResponseComponentAndData&out OutResponseCompAndData) const
	{
		auto ResponseComp = UGravityBikeFreeImpactResponseComponent::Get(Hit.Actor);
		if(ResponseComp == nullptr)
			return false;

		OutResponseCompAndData.ResponseComp = ResponseComp;

		const FHitResult HitResult = Hit.ConvertToHitResult();
		const FVector ImpactVelocity = IterationState.DeltaToTrace / IterationTime;
		OutResponseCompAndData.ImpactData = FGravityBikeFreeOnImpactData(ImpactVelocity, HitResult);

		return true;
	}

	bool CheckDeathFromWallHit(FMovementHitResult Hit, float ReflectionAngle) const
	{
		if(!GravityBikeFree::WallImpactDeath::bDieFromWallImpact)
			return false;

		if(ReflectionAngle < GravityBikeFree::WallImpactDeath::WallImpactDeathBikeAngleMax)
			return false;

		return true;
	}

	bool ShouldAlignWithWall(FMovementHitResult Hit) const
	{
		if(!IterationState.PhysicsState.GroundContact.IsAnyGroundContact())
		{
			// Only align with walls if grounded, prevents jittery air impacts
			return false;
		}

		return true;
	}

	void AlignWithWall(FMovementHitResult Hit, FMovementResolverState& State, FVector&out OutAlignWithWallImpulse, FQuat&out OutAlignWithWallDeltaRotation) const
	{
		FVector Velocity = State.GetDelta().Velocity;
		const FVector HorizontalNormal = Hit.Normal.VectorPlaneProject(CurrentWorldUp).GetSafeNormal();
		OutAlignWithWallImpulse = Velocity.ProjectOnToNormal(-HorizontalNormal);

		FQuat OutFromWallRotation = FQuat::Identity;
		bool bAlignToRightSide = HorizontalNormal.DotProduct(IterationState.CurrentRotation.RightVector) > 0;
		if(bAlignToRightSide)
			OutFromWallRotation = FQuat(CurrentWorldUp, Math::DegreesToRadians(GravityBikeFree::WallAlign::WallAlignRotationOutOffset));
		else
			OutFromWallRotation = FQuat(CurrentWorldUp, -Math::DegreesToRadians(GravityBikeFree::WallAlign::WallAlignRotationOutOffset));

		//float VelocityMultiplier = Math::Lerp(, 1, Math::Square(ReflectionAngle / 90));

		// Iterate through all the different "deltas" (velocities) on the current iteration state, and override
		// them with new velocities that are projected to align with the wall
		for(auto It : State.DeltaStates)
		{
			FMovementDelta MovementDelta = It.Value.ConvertToDelta();
			if(MovementDelta.IsNearlyZero())
				continue;

			MovementDelta = MovementDelta.PlaneProject(HorizontalNormal);

			// Rotate the velocity out slightly
			MovementDelta = MovementDelta.Rotate(OutFromWallRotation);

			MovementDelta *= GravityBikeFree::WallAlign::WallAlignVelocityMultiplier;

			// Override the delta
			State.OverrideDelta(It.Key, MovementDelta);
		}

		// Move to the hit location, offset by the normal to not penetrate
		State.CurrentLocation = Hit.Location + Hit.Normal;

		// Align the rotation with the new velocity
		FQuat NewRotation = FQuat::MakeFromXZ(State.GetDelta().Velocity, State.CurrentRotation.UpVector);
		OutAlignWithWallDeltaRotation = FQuat::GetDelta(MoveData.OriginalActorTransform.Rotation, NewRotation);
		State.CurrentRotation = NewRotation;
	}

	protected void ApplyResolvedData(UHazeMovementComponent MovementComponent) override
	{
		Super::ApplyResolvedData(MovementComponent);

		auto GravityBike = Cast<AGravityBikeFree>(MovementComponent.Owner);

		if(GravityBike.HasControl())
		{
			if(bLanded)
				GravityBike.OnLanding(LandingImpulseIntoGround, LandingHit);

			if(!Impacts.IsEmpty())
				GravityBike.BroadcastMovementImpacts(Impacts);

			if(bDeathFromWallHit)
				GravityBike.ApplyDeathFromWall(Time::FrameNumber, DeathFromWallHit);

			if(bAlignedWithWall)
				GravityBike.ApplyAlignWithWall(AlignWithWallHit, AlignWithWallImpulse, AlignWithWallDeltaRotation);
		}
	}
}