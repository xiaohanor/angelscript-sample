struct FSkylineInnerCityHitSwingBounce
{
	FHitResult HitResult;
	FVector Velocity;
	FVector ReflectNormal;
};

class USkylineInnerCityHitSwingResolver : USweepingMovementResolver
{
	default RequiredDataType = USkylineInnerCityHitSwingMovementData;

	private USkylineInnerCityHitSwingMovementData SwingMoveData;
	TArray<FSkylineInnerCityHitSwingBounce> Bounces;

	ASkylineInnerCityHitSwing HitSwing;

	void PrepareResolver(const UBaseMovementData Movement) override
	{
		Super::PrepareResolver(Movement);

		SwingMoveData = Cast<USkylineInnerCityHitSwingMovementData>(Movement);
		HitSwing = Cast<ASkylineInnerCityHitSwing>(Owner);

		// We use an array for bounces so that we can handle multiple hits in one frame.
		// Probably not necessary, but it *is* more correct
		Bounces.Reset();
	}

	FMovementDelta GenerateIterationDelta() const override
	{
		FMovementDelta MovementDelta = Super::GenerateIterationDelta();
		if (!SwingMoveData.bShouldClampToPlane)
			return MovementDelta;

		// If we are moving upwards for any reason, we clamp it to be along the plane since we don't want to be able to leave the area
		if(MovementDelta.Velocity.DotProduct(SwingMoveData.UsedMoveClampPlaneNormal) > 0)
		{
			return MovementDelta.GetHorizontalPart(SwingMoveData.UsedMoveClampPlaneNormal);
		}
		else
		{
			return MovementDelta;
		}
	}
	
	EMovementResolverHandleMovementImpactResult HandleMovementImpact(FMovementHitResult Hit, EMovementResolverAnyShapeTraceImpactType ImpactType) override
	{
		// If this was NOT an iteration sweep, i.e it was a ground trace, we ignore this impact
		if(ImpactType != EMovementResolverAnyShapeTraceImpactType::Iteration)
			return EMovementResolverHandleMovementImpactResult::Continue;
		
		// Check if we have bounced!
		if(Bounce(IterationState, Hit))
			return EMovementResolverHandleMovementImpactResult::Skip;	// If we have bounced, skip this iteration and do another one with the new velocity

		return EMovementResolverHandleMovementImpactResult::Continue;
	}

	bool Bounce(FMovementResolverState& State, FMovementHitResult MovementHit)
	{
		// The hit was not a wall, don't bounce
		if(!MovementHit.IsWallImpact())
			return false;

		// Only bounce when moving along the ground
		if(!State.PhysicsState.GroundContact.IsAnyGroundContact())
			return false;

		const FVector CurrentVelocity = State.GetDelta().Velocity;
		const float CurrentSpeed = CurrentVelocity.Size();

		// Our speed was too low, don't bounce
		if(CurrentSpeed < InnerCityHitSwing::MinSpeedToBounce)
			return false;

		FSkylineInnerCityHitSwingBounce BounceData;
		BounceData.Velocity = CurrentVelocity;
		FHitResult HitResult = MovementHit.ConvertToHitResult();
		
		const FVector FlatNormal = MovementHit.Normal.VectorPlaneProject(CurrentWorldUp).GetSafeNormal();

		// Iterate through all the different "deltas" (velocities) on the current iteration state, and override
		// them with new velocities that are reflected off the wall
		for(auto It : State.DeltaStates)
		{
			FMovementDelta MovementDelta = It.Value.ConvertToDelta();
			if(MovementDelta.IsNearlyZero())
				continue;

			if (HitMioWhileRespawning(HitResult)) // ugly :shrug: don't bounce on mio if we just respawned, we need to get out of closet lol
				continue;

			// Split the vertical and horizontal components
			FMovementDelta VerticalDelta = MovementDelta.GetVerticalPart(CurrentWorldUp);
			FMovementDelta HorizontalDelta = MovementDelta - VerticalDelta;

			// Project the impact normal on the ground plane, so that we don't reflect up and away from the floor

			// Bounce the delta off the wall normal
			HorizontalDelta = HorizontalDelta.Bounce(FlatNormal, InnerCityHitSwing::Restitution);

			// Recombine the modified horizontal delta with the original vertical delta
			MovementDelta = HorizontalDelta + VerticalDelta;

			// Override the delta
			State.OverrideDelta(It.Key, MovementDelta);
		}

		// Store the hit in Bounces
		BounceData.HitResult = HitResult;
		BounceData.ReflectNormal = FlatNormal;
		Bounces.Add(BounceData);

		State.CurrentLocation = MovementHit.Location;

		return true;
	}

	bool HitMioWhileRespawning(FHitResult HitResult) const
	{
		if (HitResult.Actor == nullptr)
			return false;

		auto HitPlayer = Cast<AHazePlayerCharacter>(HitResult.Actor);
		if(HitPlayer == nullptr)
			return false;

		if(!HitPlayer.IsMio())
			return false;

		if (!HitSwing.JustRespawned())
			return false;
			
		return true;
	}


	void ApplyResolvedData(UHazeMovementComponent MovementComponent) override
	{
		Super::ApplyResolvedData(MovementComponent);

		// After we are finished resolving, we go through and apply all impacts on the actor
		for(const FSkylineInnerCityHitSwingBounce Bounce : Bounces)
		{
			HitSwing.OnBounce(Bounce);
		}
	}
};