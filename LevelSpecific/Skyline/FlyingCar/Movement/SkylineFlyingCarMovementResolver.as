struct FSkylineFlyingCarImpactDataAndResponseComponent
{
	UPROPERTY()
	USkylineFlyingCarImpactResponseComponent ResponseComp;

	UPROPERTY()
	FVector Velocity;

	UPROPERTY()
	FHitResult HitResult;
};

class USkylineFlyingCarMovementResolver : USweepingMovementResolver
{
	default RequiredDataType = USkylineFlyingCarMovementData;

	USkylineFlyingCarMovementData MoveData;

	// Generic Collisions
	TArray<FSkylineFlyingCarCollision> Collisions;
	bool bBounced = false;

	// Impacts with Response Components
	TArray<FSkylineFlyingCarImpactDataAndResponseComponent> ResponseComponentImpacts;

	const float COLLISION_DIRECTION_THRESHOLD = 0.1;

	// Anything higher than this is death
	const float MaxImpactAngleForBounce = 45;

	void PrepareResolver(const UBaseMovementData Movement) override
	{
		Super::PrepareResolver(Movement);

		MoveData = Cast<USkylineFlyingCarMovementData>(Movement);

		Collisions.Reset();
		bBounced = false;

		ResponseComponentImpacts.Reset();
	}

	bool PreResolveStartPenetrating(FMovementHitResult Impact) override
	{
		FSkylineFlyingCarImpactDataAndResponseComponent ImpactAndResponseComp;
		if(CollideWithResponseComponent(Impact, ImpactAndResponseComp))
		{
			ResponseComponentImpacts.Add(ImpactAndResponseComp);

			if(ImpactAndResponseComp.ResponseComp.bIgnoreAfterImpact)
			{
				IterationTraceSettings.AddPermanentIgnoredActor(ImpactAndResponseComp.ResponseComp.Owner);
				return true;
			}
		}

		return false;
	}

	EMovementResolverHandleMovementImpactResult HandleMovementImpact(
		FMovementHitResult Hit,
		EMovementResolverAnyShapeTraceImpactType ImpactType) override
	{
		FSkylineFlyingCarImpactDataAndResponseComponent ImpactAndResponseComp;
		if(CollideWithResponseComponent(Hit, ImpactAndResponseComp))
		{
			ResponseComponentImpacts.Add(ImpactAndResponseComp);

			if(ImpactAndResponseComp.ResponseComp.bIgnoreAfterImpact)
			{
				IterationTraceSettings.AddPermanentIgnoredActor(ImpactAndResponseComp.ResponseComp.Owner);
				return EMovementResolverHandleMovementImpactResult::Skip;
			}
		}

		FSkylineFlyingCarCollision CarCollision;
		if(CheckForCollisions(Hit, CarCollision))
		{
			Collisions.Add(CarCollision);

			switch(CarCollision.Type)
			{
				case ESkylineFlyingCarCollisionType::Bounce:
				{
					// Place us on the impact location
					IterationState.ApplyMovement(Hit.Time, Hit.Location);

					// Bounce off of the collision
					BounceMovement(IterationState, CarCollision.HitResult.ImpactNormal);
					bBounced = true;

					// Change the rotation as well
					FVector Delta = IterationState.GetDelta().Delta;
					FQuat NewRotation = FQuat::MakeFromXZ(Delta, IterationState.CurrentRotation.UpVector);
					IterationState.CurrentRotation = NewRotation;

					return EMovementResolverHandleMovementImpactResult::Skip;
				}

				case ESkylineFlyingCarCollisionType::TotalLoss:
				{
					// Explode!
					return EMovementResolverHandleMovementImpactResult::Finish;
				}
			}
		}

		return EMovementResolverHandleMovementImpactResult::Continue;
	}

	/**
	 * This function used to be on the actor, and used an additional trace before the movement traces.
	 * This could fight the movement traces, so I moved it to the resolver to unite all sweeps here /FB
	 */
	bool CheckForCollisions(FMovementHitResult Hit, FSkylineFlyingCarCollision& OutCollision)
	{
		if (!Hit.IsValidBlockingHit())
			return false;

		OutCollision.HitResult = Hit.ConvertToHitResult();
		if (OutCollision.HitResult.Component.HasTag(FlyingCarTags::CollisionTag::NonLethal))
			return false;

		const FVector Velocity = IterationState.GetDelta().Velocity;

		OutCollision.Type = GetCollisionType(Velocity, OutCollision.HitResult.ImpactNormal);

		const FVector ToImpact = (Hit.ImpactPoint - IterationState.CurrentLocation).GetSafeNormal();
		float ImpactDot = ToImpact.DotProduct(IterationState.CurrentRotation.RightVector);

		if(Math::Abs(ImpactDot) > COLLISION_DIRECTION_THRESHOLD)
			ImpactDot = Math::Sign(ImpactDot);

		OutCollision.Direction = ImpactDot;

		return true;
	}

	ESkylineFlyingCarCollisionType GetCollisionType(FVector Velocity, FVector ImpactNormal) const
	{
		// Debug::DrawDebugDirectionArrow(Owner.ActorLocation, ImpactNormal, 400, 100, FLinearColor::DPink, 3, 5);
		// Debug::DrawDebugDirectionArrow(Owner.ActorLocation, Velocity, 400, 100, FLinearColor::Green, 3, 5);

		float VelocityImpactProjection = Velocity.GetSafeNormal().DotProduct(-ImpactNormal);
		if (VelocityImpactProjection < 0)
			return ESkylineFlyingCarCollisionType::Bounce;

		// Check for collision angle
		float ImpactAngle = Math::RadiansToDegrees(Math::Acos(VelocityImpactProjection));
		if (ImpactAngle > (90. - MaxImpactAngleForBounce))
			return ESkylineFlyingCarCollisionType::Bounce;

		return ESkylineFlyingCarCollisionType::TotalLoss;
	}

	void BounceMovement(FMovementResolverState& State, FVector Normal) const
	{
		for(auto It : State.DeltaStates)
		{
			FMovementDelta MovementDelta = It.Value.ConvertToDelta();
			if(MovementDelta.IsNearlyZero())
				continue;

			MovementDelta = MovementDelta.Bounce(Normal, 1);

			State.OverrideDelta(It.Key, MovementDelta);
		}
	}

	bool CollideWithResponseComponent(FMovementHitResult Hit, FSkylineFlyingCarImpactDataAndResponseComponent&out OutResult) const
	{
		if(!Hit.bBlockingHit)
			return false;

		auto ResponseComp = USkylineFlyingCarImpactResponseComponent::Get(Hit.Actor);
		if(ResponseComp == nullptr)
			return false;

		OutResult.ResponseComp = ResponseComp;
		OutResult.Velocity = IterationState.GetDelta().Velocity;
		OutResult.HitResult = Hit.ConvertToHitResult();
		return true;
	}

	void ApplyResolvedData(UHazeMovementComponent MovementComponent) override
	{
		Super::ApplyResolvedData(MovementComponent);

		auto FlyingCar = Cast<ASkylineFlyingCar>(MovementComponent.Owner);

		if(FlyingCar.HasControl())
		{
			if(!Collisions.IsEmpty())
				FlyingCar.OnResolverCollisions(Collisions);

			if(!ResponseComponentImpacts.IsEmpty())
				FlyingCar.OnResponseComponentImpacts(ResponseComponentImpacts);

			if(bBounced)
			{
				const FQuat NewMeshRotation = IterationState.CurrentRotation;
				const FQuat BounceDeltaRotation = NewMeshRotation * MoveData.OriginalActorTransform.Rotation.Inverse();
				FlyingCar.ApplyBounceDeltaRotation(BounceDeltaRotation);
			}
		}
	}
}