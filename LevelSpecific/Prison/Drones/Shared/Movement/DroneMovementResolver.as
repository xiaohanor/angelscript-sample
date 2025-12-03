class UDroneMovementResolver : USweepingMovementResolver
{
	default RequiredDataType = UDroneMovementData;

	const UDroneMovementData DroneData;
	bool bHasBounced = false;

	void PrepareResolver(const UBaseMovementData Movement) override
	{
		Super::PrepareResolver(Movement);

		DroneData = Cast<UDroneMovementData>(Movement);
		bHasBounced = false;
	}
	
	EMovementResolverHandleMovementImpactResult HandleMovementImpact(FMovementHitResult Hit, EMovementResolverAnyShapeTraceImpactType ImpactType) override
	{
		if(Bounce(IterationState, Hit))
		{
			bHasBounced = true;
			return EMovementResolverHandleMovementImpactResult::Skip;
		}

		return EMovementResolverHandleMovementImpactResult::Continue;
	}

	protected FVector GetNormalForImpactTypeGeneration(FHitResult HitResult) const override
	{
		return HitResult.Normal;
	}

	bool Bounce(FMovementResolverState& State, FMovementHitResult MovementHit) const
	{
		if(!DroneData.bCanBounce)
			return false;

		if(DroneData.OriginalContacts.GroundContact.IsValidBlockingHit())
			return false;

		if(State.PhysicsState.GroundContact.IsValidBlockingHit())
			return false;

		const FVector CurrentVelocity = State.GetDelta().Velocity;

		// Not falling fast enough
		if(CurrentVelocity.Z > DroneData.BounceMinimumVerticalSpeed)
			return false;

		// Too steep
		if(MovementHit.Normal.GetAngleDegreesTo(CurrentWorldUp) > DroneData.BounceAngleThreshold)
			return false;

		float BounceFactor = DroneData.BounceRestitution;

		if(DroneData.BounceFromHorizontalFactorOverSpeedSpline.GetNumKeys() > 0)
		{
			const FVector HorizontalVelocity = CurrentVelocity.VectorPlaneProject(FVector::UpVector);
			const float HorizontalSpeed = HorizontalVelocity.Size();
			const float FactorFromHorizontalSpeed = DroneData.BounceFromHorizontalFactorOverSpeedSpline.GetFloatValue(HorizontalSpeed);
			BounceFactor *= FactorFromHorizontalSpeed;
		}

		if(BounceFactor < KINDA_SMALL_NUMBER)
			return false;

		for(auto It : State.DeltaStates)
		{
			FMovementDelta MovementDelta = It.Value.ConvertToDelta();
			if(MovementDelta.IsNearlyZero())
				continue;

			MovementDelta = MovementDelta.Bounce(FVector::UpVector, BounceFactor);

			State.OverrideDelta(It.Key, MovementDelta);
		}

		State.CurrentLocation = MovementHit.Location;

		return true;
	}

	FMovementDelta ProjectDeltaUponGroundedBlockingImpact(
		FMovementDelta DeltaState,
		FMovementHitResult Impact,
		FMovementHitResult GroundedState) const override
	{
		if(Impact.IsWallImpact())
		{
			// Just project onto the impact normal, instead of rolling along the wall impact
			// This helps us roll over low walls
			return DeltaState.GetHorizontalPart(Impact.Normal);
		}
		else
		{
			return Super::ProjectDeltaUponGroundedBlockingImpact(DeltaState, Impact, GroundedState);
		}
	}

	void ApplyResolvedData(UHazeMovementComponent MovementComponent) override
	{
		Super::ApplyResolvedData(MovementComponent);

		if(bHasBounced)
		{
			if(DroneData.bIsSwarmDrone)
			{
				auto BounceComp = USwarmDroneBounceComponent::Get(MovementComponent.Owner);
				if(BounceComp != nullptr)
					BounceComp.LastResolverBounceFrame = Time::FrameNumber;
			}
			else
			{
				auto BounceComp = UMagnetDroneBounceComponent::Get(MovementComponent.Owner);
				if(BounceComp != nullptr)
					BounceComp.LastResolverBounceFrame = Time::FrameNumber;
			}
		}
	}
};